package refactor

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudformation"
	cftypes "github.com/aws/aws-sdk-go-v2/service/cloudformation/types"
)

type StackDef struct {
	StackName    string `json:"stackName"`
	TemplatePath string `json:"templatePath"`
}

type Location struct {
	StackName         string `json:"stackName"`
	LogicalResourceID string `json:"logicalResourceId"`
}

type Mapping struct {
	Source      Location `json:"source"`
	Destination Location `json:"destination"`
}

type CreateRequest struct {
	StackDefinitions    []StackDef `json:"stackDefinitions"`
	ResourceMappings    []Mapping  `json:"resourceMappings"`
	Description         string     `json:"description,omitempty"`
	EnableStackCreation bool       `json:"enableStackCreation,omitempty"`
}

type CreateResponse struct {
	RefactorID string `json:"refactorId"`
}

type DescribeResponse struct {
	RefactorID            string `json:"refactorId"`
	Status                string `json:"status"`
	StatusReason          string `json:"statusReason,omitempty"`
	ExecutionStatus       string `json:"executionStatus,omitempty"`
	ExecutionStatusReason string `json:"executionStatusReason,omitempty"`
}

type Action struct {
	Action             string    `json:"action"`
	Entity             string    `json:"entity"`
	Detection          string    `json:"detection"`
	DetectionReason    string    `json:"detectionReason,omitempty"`
	Description        string    `json:"description,omitempty"`
	PhysicalResourceID string    `json:"physicalResourceId,omitempty"`
	Source             *Location `json:"source,omitempty"`
	Destination        *Location `json:"destination,omitempty"`
}

func newClient(ctx context.Context, profile, region string) (*cloudformation.Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithSharedConfigProfile(profile),
		config.WithRegion(region),
	)
	if err != nil {
		return nil, err
	}
	return cloudformation.NewFromConfig(cfg), nil
}

func Create(ctx context.Context, profile, region string, req CreateRequest) (*CreateResponse, error) {
	cf, err := newClient(ctx, profile, region)
	if err != nil {
		return nil, err
	}

	defs := make([]cftypes.StackDefinition, 0, len(req.StackDefinitions))
	for _, d := range req.StackDefinitions {
		body, err := os.ReadFile(d.TemplatePath)
		if err != nil {
			return nil, fmt.Errorf("read template %s: %w", d.TemplatePath, err)
		}
		defs = append(defs, cftypes.StackDefinition{
			StackName:    aws.String(d.StackName),
			TemplateBody: aws.String(string(body)),
		})
	}

	mappings := make([]cftypes.ResourceMapping, 0, len(req.ResourceMappings))
	for _, m := range req.ResourceMappings {
		mappings = append(mappings, cftypes.ResourceMapping{
			Source: &cftypes.ResourceLocation{
				StackName:         aws.String(m.Source.StackName),
				LogicalResourceId: aws.String(m.Source.LogicalResourceID),
			},
			Destination: &cftypes.ResourceLocation{
				StackName:         aws.String(m.Destination.StackName),
				LogicalResourceId: aws.String(m.Destination.LogicalResourceID),
			},
		})
	}

	input := &cloudformation.CreateStackRefactorInput{
		StackDefinitions: defs,
		ResourceMappings: mappings,
	}
	if req.Description != "" {
		input.Description = aws.String(req.Description)
	}
	if req.EnableStackCreation {
		input.EnableStackCreation = aws.Bool(true)
	}

	out, err := cf.CreateStackRefactor(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("CreateStackRefactor: %w", err)
	}
	return &CreateResponse{RefactorID: aws.ToString(out.StackRefactorId)}, nil
}

func Describe(ctx context.Context, profile, region, refactorID string) (*DescribeResponse, error) {
	cf, err := newClient(ctx, profile, region)
	if err != nil {
		return nil, err
	}
	out, err := cf.DescribeStackRefactor(ctx, &cloudformation.DescribeStackRefactorInput{
		StackRefactorId: aws.String(refactorID),
	})
	if err != nil {
		return nil, fmt.Errorf("DescribeStackRefactor: %w", err)
	}
	return &DescribeResponse{
		RefactorID:            aws.ToString(out.StackRefactorId),
		Status:                string(out.Status),
		StatusReason:          aws.ToString(out.StatusReason),
		ExecutionStatus:       string(out.ExecutionStatus),
		ExecutionStatusReason: aws.ToString(out.ExecutionStatusReason),
	}, nil
}

func ListActions(ctx context.Context, profile, region, refactorID string) ([]Action, error) {
	cf, err := newClient(ctx, profile, region)
	if err != nil {
		return nil, err
	}
	var actions []Action
	var nextToken *string
	for {
		out, err := cf.ListStackRefactorActions(ctx, &cloudformation.ListStackRefactorActionsInput{
			StackRefactorId: aws.String(refactorID),
			NextToken:       nextToken,
		})
		if err != nil {
			return nil, err
		}
		for _, a := range out.StackRefactorActions {
			act := Action{
				Action:             string(a.Action),
				Entity:             string(a.Entity),
				Detection:          string(a.Detection),
				DetectionReason:    aws.ToString(a.DetectionReason),
				Description:        aws.ToString(a.Description),
				PhysicalResourceID: aws.ToString(a.PhysicalResourceId),
			}
			if a.ResourceMapping != nil {
				if a.ResourceMapping.Source != nil {
					act.Source = &Location{
						StackName:         aws.ToString(a.ResourceMapping.Source.StackName),
						LogicalResourceID: aws.ToString(a.ResourceMapping.Source.LogicalResourceId),
					}
				}
				if a.ResourceMapping.Destination != nil {
					act.Destination = &Location{
						StackName:         aws.ToString(a.ResourceMapping.Destination.StackName),
						LogicalResourceID: aws.ToString(a.ResourceMapping.Destination.LogicalResourceId),
					}
				}
			}
			actions = append(actions, act)
		}
		if out.NextToken == nil || aws.ToString(out.NextToken) == "" {
			break
		}
		nextToken = out.NextToken
	}
	if actions == nil {
		actions = []Action{}
	}
	return actions, nil
}

func Execute(ctx context.Context, profile, region, refactorID string) error {
	cf, err := newClient(ctx, profile, region)
	if err != nil {
		return err
	}
	if _, err := cf.ExecuteStackRefactor(ctx, &cloudformation.ExecuteStackRefactorInput{
		StackRefactorId: aws.String(refactorID),
	}); err != nil {
		return fmt.Errorf("ExecuteStackRefactor: %w", err)
	}
	return nil
}
