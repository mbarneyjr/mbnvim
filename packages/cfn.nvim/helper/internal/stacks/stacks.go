package stacks

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudformation"
	cftypes "github.com/aws/aws-sdk-go-v2/service/cloudformation/types"
)

type Summary struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

func List(ctx context.Context, profile, region string) ([]Summary, error) {
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithSharedConfigProfile(profile),
		config.WithRegion(region),
	)
	if err != nil {
		return nil, err
	}
	cf := cloudformation.NewFromConfig(cfg)

	var out []Summary
	var nextToken *string
	for {
		resp, err := cf.ListStacks(ctx, &cloudformation.ListStacksInput{
			NextToken: nextToken,
		})
		if err != nil {
			return nil, err
		}
		for _, s := range resp.StackSummaries {
			if s.StackStatus == cftypes.StackStatusDeleteComplete {
				continue
			}
			out = append(out, Summary{
				Name:   aws.ToString(s.StackName),
				Status: string(s.StackStatus),
			})
		}
		if resp.NextToken == nil || aws.ToString(resp.NextToken) == "" {
			break
		}
		nextToken = resp.NextToken
	}
	return out, nil
}
