package refactor

import (
	"context"
	"fmt"
	"os"
	"time"

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

type Action struct {
	Action          string    `json:"action"`
	Entity          string    `json:"entity"`
	Detection       string    `json:"detection"`
	DetectionReason string    `json:"detectionReason,omitempty"`
	Description     string    `json:"description,omitempty"`
	Source          *Location `json:"source,omitempty"`
	Destination     *Location `json:"destination,omitempty"`
}

type CreateResponse struct {
	RefactorID string   `json:"refactorId"`
	Status     string   `json:"status"`
	StatusMsg  string   `json:"statusMessage,omitempty"`
	Actions    []Action `json:"actions"`
}

type ExecuteResponse struct {
	Status    string `json:"status"`
	StatusMsg string `json:"statusMessage,omitempty"`
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

	createInput := &cloudformation.CreateStackRefactorInput{
		StackDefinitions: defs,
		ResourceMappings: mappings,
	}
	if req.Description != "" {
		createInput.Description = aws.String(req.Description)
	}
	if req.EnableStackCreation {
		createInput.EnableStackCreation = aws.Bool(true)
	}

	out, err := cf.CreateStackRefactor(ctx, createInput)
	if err != nil {
		return nil, fmt.Errorf("CreateStackRefactor: %w", err)
	}
	id := aws.ToString(out.StackRefactorId)

	status, statusMsg, err := waitForStatus(ctx, cf, id, []string{"CREATE_COMPLETE", "CREATE_FAILED"}, 5*time.Minute)
	if err != nil {
		return nil, err
	}

	resp := &CreateResponse{
		RefactorID: id,
		Status:     status,
		StatusMsg:  statusMsg,
		Actions:    []Action{},
	}

	if status == "CREATE_COMPLETE" {
		actions, err := listActions(ctx, cf, id)
		if err != nil {
			return nil, fmt.Errorf("ListStackRefactorActions: %w", err)
		}
		resp.Actions = actions
	}

	return resp, nil
}

func Execute(ctx context.Context, profile, region, refactorID string) (*ExecuteResponse, error) {
	cf, err := newClient(ctx, profile, region)
	if err != nil {
		return nil, err
	}

	if _, err := cf.ExecuteStackRefactor(ctx, &cloudformation.ExecuteStackRefactorInput{
		StackRefactorId: aws.String(refactorID),
	}); err != nil {
		return nil, fmt.Errorf("ExecuteStackRefactor: %w", err)
	}

	terminal := []string{"EXECUTE_COMPLETE", "EXECUTE_FAILED", "ROLLBACK_COMPLETE", "ROLLBACK_FAILED", "OBSOLETE"}
	status, statusMsg, err := waitForExecutionStatus(ctx, cf, refactorID, terminal, 30*time.Minute)
	if err != nil {
		return nil, err
	}
	return &ExecuteResponse{Status: status, StatusMsg: statusMsg}, nil
}

func waitForStatus(ctx context.Context, cf *cloudformation.Client, id string, terminal []string, timeout time.Duration) (string, string, error) {
	deadline := time.Now().Add(timeout)
	for {
		out, err := cf.DescribeStackRefactor(ctx, &cloudformation.DescribeStackRefactorInput{
			StackRefactorId: aws.String(id),
		})
		if err != nil {
			return "", "", fmt.Errorf("DescribeStackRefactor: %w", err)
		}
		status := string(out.Status)
		for _, t := range terminal {
			if t == status {
				return status, aws.ToString(out.StatusReason), nil
			}
		}
		if time.Now().After(deadline) {
			return status, aws.ToString(out.StatusReason), fmt.Errorf("timed out waiting for refactor %s (last status %s)", id, status)
		}
		select {
		case <-ctx.Done():
			return "", "", ctx.Err()
		case <-time.After(2 * time.Second):
		}
	}
}

func waitForExecutionStatus(ctx context.Context, cf *cloudformation.Client, id string, terminal []string, timeout time.Duration) (string, string, error) {
	deadline := time.Now().Add(timeout)
	for {
		out, err := cf.DescribeStackRefactor(ctx, &cloudformation.DescribeStackRefactorInput{
			StackRefactorId: aws.String(id),
		})
		if err != nil {
			return "", "", fmt.Errorf("DescribeStackRefactor: %w", err)
		}
		status := string(out.ExecutionStatus)
		for _, t := range terminal {
			if t == status {
				return status, aws.ToString(out.ExecutionStatusReason), nil
			}
		}
		if time.Now().After(deadline) {
			return status, aws.ToString(out.ExecutionStatusReason), fmt.Errorf("timed out waiting for refactor %s execution (last status %s)", id, status)
		}
		select {
		case <-ctx.Done():
			return "", "", ctx.Err()
		case <-time.After(5 * time.Second):
		}
	}
}

func listActions(ctx context.Context, cf *cloudformation.Client, id string) ([]Action, error) {
	var actions []Action
	var nextToken *string
	for {
		out, err := cf.ListStackRefactorActions(ctx, &cloudformation.ListStackRefactorActionsInput{
			StackRefactorId: aws.String(id),
			NextToken:       nextToken,
		})
		if err != nil {
			return nil, err
		}
		for _, a := range out.StackRefactorActions {
			act := Action{
				Action:          string(a.Action),
				Entity:          string(a.Entity),
				Detection:       string(a.Detection),
				DetectionReason: aws.ToString(a.DetectionReason),
				Description:     aws.ToString(a.Description),
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
	return actions, nil
}
