package changeset

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudformation"
	cftypes "github.com/aws/aws-sdk-go-v2/service/cloudformation/types"
)

type Resource struct {
	LogicalID    string          `json:"logicalId"`
	ResourceType string          `json:"resourceType"`
	Identifier   json.RawMessage `json:"identifier"`
}

type ImportRequest struct {
	StackName    string     `json:"stackName"`
	TemplatePath string     `json:"templatePath"`
	Resources    []Resource `json:"resources"`
	Capabilities []string   `json:"capabilities"`
}

type ImportResponse struct {
	ChangeSetID   string `json:"changeSetId"`
	StackID       string `json:"stackId"`
	ChangeSetName string `json:"changeSetName"`
}

func Import(ctx context.Context, profile, region string, req ImportRequest) (*ImportResponse, error) {
	body, err := os.ReadFile(req.TemplatePath)
	if err != nil {
		return nil, fmt.Errorf("read template: %w", err)
	}
	templateBody := string(body)

	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithSharedConfigProfile(profile),
		config.WithRegion(region),
	)
	if err != nil {
		return nil, err
	}
	cf := cloudformation.NewFromConfig(cfg)

	summary, err := cf.GetTemplateSummary(ctx, &cloudformation.GetTemplateSummaryInput{
		TemplateBody: aws.String(templateBody),
	})
	if err != nil {
		return nil, fmt.Errorf("GetTemplateSummary: %w", err)
	}
	idKeys := make(map[string]string)
	for _, ris := range summary.ResourceIdentifierSummaries {
		if len(ris.ResourceIdentifiers) > 0 {
			idKeys[aws.ToString(ris.ResourceType)] = ris.ResourceIdentifiers[0]
		}
	}

	resourcesToImport := make([]cftypes.ResourceToImport, 0, len(req.Resources))
	for _, r := range req.Resources {
		identifier, err := buildIdentifier(r, idKeys)
		if err != nil {
			return nil, err
		}
		resourcesToImport = append(resourcesToImport, cftypes.ResourceToImport{
			ResourceType:       aws.String(r.ResourceType),
			LogicalResourceId:  aws.String(r.LogicalID),
			ResourceIdentifier: identifier,
		})
	}

	caps := make([]cftypes.Capability, 0, len(req.Capabilities))
	for _, c := range req.Capabilities {
		caps = append(caps, cftypes.Capability(c))
	}

	changeSetName := fmt.Sprintf("%s-import-%s", req.StackName, time.Now().UTC().Format("20060102-150405"))

	out, err := cf.CreateChangeSet(ctx, &cloudformation.CreateChangeSetInput{
		StackName:         aws.String(req.StackName),
		ChangeSetName:     aws.String(changeSetName),
		ChangeSetType:     cftypes.ChangeSetTypeImport,
		TemplateBody:      aws.String(templateBody),
		ResourcesToImport: resourcesToImport,
		Capabilities:      caps,
	})
	if err != nil {
		return nil, fmt.Errorf("CreateChangeSet: %w", err)
	}

	return &ImportResponse{
		ChangeSetID:   aws.ToString(out.Id),
		StackID:       aws.ToString(out.StackId),
		ChangeSetName: changeSetName,
	}, nil
}

func buildIdentifier(r Resource, idKeys map[string]string) (map[string]string, error) {
	if len(r.Identifier) == 0 {
		return nil, fmt.Errorf("missing identifier for %s", r.LogicalID)
	}
	var asMap map[string]string
	if err := json.Unmarshal(r.Identifier, &asMap); err == nil {
		return asMap, nil
	}
	var asString string
	if err := json.Unmarshal(r.Identifier, &asString); err != nil {
		return nil, fmt.Errorf("identifier for %s is neither string nor object", r.LogicalID)
	}
	key, ok := idKeys[r.ResourceType]
	if !ok {
		return nil, fmt.Errorf("no identifier key found in template summary for %s", r.ResourceType)
	}
	return map[string]string{key: asString}, nil
}
