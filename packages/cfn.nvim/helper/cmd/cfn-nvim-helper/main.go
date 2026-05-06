package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"

	"github.com/spf13/cobra"

	"github.com/mbarney/cfn.nvim/helper/internal/changeset"
	"github.com/mbarney/cfn.nvim/helper/internal/credentials"
	"github.com/mbarney/cfn.nvim/helper/internal/jwe"
	"github.com/mbarney/cfn.nvim/helper/internal/refactor"
	"github.com/mbarney/cfn.nvim/helper/internal/stacks"
)

func main() {
	root := &cobra.Command{
		Use:           "cfn-nvim-helper",
		Short:         "Helper binary for cfn.nvim",
		SilenceUsage:  true,
		SilenceErrors: true,
	}

	root.AddCommand(jweCmd())
	root.AddCommand(credentialsCmd())
	root.AddCommand(changesetCmd())
	root.AddCommand(refactorCmd())
	root.AddCommand(stacksCmd())

	if err := root.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func jweCmd() *cobra.Command {
	cmd := &cobra.Command{Use: "jwe", Short: "JWE operations"}

	genkey := &cobra.Command{
		Use:   "genkey",
		Short: "Print a base64-encoded random key suitable for cfn-lsp-server",
		RunE: func(cmd *cobra.Command, args []string) error {
			key, err := jwe.GenerateKey()
			if err != nil {
				return err
			}
			fmt.Println(key)
			return nil
		},
	}

	cmd.AddCommand(genkey)
	return cmd
}

func credentialsCmd() *cobra.Command {
	cmd := &cobra.Command{Use: "credentials", Short: "AWS credential operations"}

	resolve := &cobra.Command{
		Use:   "resolve",
		Short: "Resolve credentials for a profile and emit a JWE token",
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")
			jweKey, _ := cmd.Flags().GetString("jwe-key")

			ctx := context.Background()
			r, err := credentials.Resolve(ctx, profile, region)
			if err != nil {
				return err
			}

			payload := map[string]any{
				"data": map[string]any{
					"profile":         profile,
					"accessKeyId":     r.AccessKeyID,
					"secretAccessKey": r.SecretAccessKey,
					"sessionToken":    r.SessionToken,
					"region":          r.Region,
				},
			}
			plaintext, err := json.Marshal(payload)
			if err != nil {
				return err
			}
			token, err := jwe.Encrypt(plaintext, jweKey)
			if err != nil {
				return err
			}

			out := map[string]any{
				"jwe":     token,
				"region":  r.Region,
				"account": r.Account,
				"expiry":  r.Expiry,
			}
			return json.NewEncoder(os.Stdout).Encode(out)
		},
	}
	resolve.Flags().String("profile", "", "AWS profile name (required)")
	resolve.Flags().String("region", "", "Override region resolved from the profile")
	resolve.Flags().String("jwe-key", "", "JWE encryption key (required)")
	_ = resolve.MarkFlagRequired("profile")
	_ = resolve.MarkFlagRequired("jwe-key")

	listProfiles := &cobra.Command{
		Use:   "list-profiles",
		Short: "Print available AWS profile names as a JSON array",
		RunE: func(_ *cobra.Command, _ []string) error {
			profiles, err := credentials.ListProfiles()
			if err != nil {
				return err
			}
			return json.NewEncoder(os.Stdout).Encode(profiles)
		},
	}

	cmd.AddCommand(resolve, listProfiles)
	return cmd
}

func changesetCmd() *cobra.Command {
	cmd := &cobra.Command{Use: "changeset", Short: "CloudFormation change set operations"}

	importCmd := &cobra.Command{
		Use:   "import",
		Short: "Create an IMPORT change set from a JSON payload on stdin",
		Long: `Reads a JSON payload from stdin describing the import:
  {
    "stackName": "string",
    "templatePath": "string",
    "resources": [{"logicalId":"...","resourceType":"...","identifier":"..."|{"K":"V"}}],
    "capabilities": ["CAPABILITY_NAMED_IAM"]
  }
Emits JSON on stdout: { "changeSetId": "...", "stackId": "...", "changeSetName": "..." }`,
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")

			data, err := io.ReadAll(os.Stdin)
			if err != nil {
				return fmt.Errorf("read stdin: %w", err)
			}
			var req changeset.ImportRequest
			if err := json.Unmarshal(data, &req); err != nil {
				return fmt.Errorf("parse request: %w", err)
			}

			ctx := context.Background()
			resp, err := changeset.Import(ctx, profile, region, req)
			if err != nil {
				return err
			}
			return json.NewEncoder(os.Stdout).Encode(resp)
		},
	}
	importCmd.Flags().String("profile", "", "AWS profile name (required)")
	importCmd.Flags().String("region", "", "AWS region (required)")
	_ = importCmd.MarkFlagRequired("profile")
	_ = importCmd.MarkFlagRequired("region")

	cmd.AddCommand(importCmd)
	return cmd
}

func refactorCmd() *cobra.Command {
	cmd := &cobra.Command{Use: "refactor", Short: "CloudFormation stack refactor operations"}

	create := &cobra.Command{
		Use:   "create",
		Short: "Create a stack refactor from a JSON payload on stdin (non-blocking)",
		Long: `Reads a JSON payload from stdin describing the refactor:
  {
    "stackDefinitions": [{"stackName": "...", "templatePath": "..."}],
    "resourceMappings": [
      {"source": {"stackName":"...","logicalResourceId":"..."},
       "destination": {"stackName":"...","logicalResourceId":"..."}}
    ],
    "enableStackCreation": false
  }
Returns immediately after CreateStackRefactor; poll status with 'refactor describe'.
Emits JSON: { "refactorId":"..." }`,
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")

			data, err := io.ReadAll(os.Stdin)
			if err != nil {
				return fmt.Errorf("read stdin: %w", err)
			}
			var req refactor.CreateRequest
			if err := json.Unmarshal(data, &req); err != nil {
				return fmt.Errorf("parse request: %w", err)
			}

			resp, err := refactor.Create(context.Background(), profile, region, req)
			if err != nil {
				return err
			}
			return json.NewEncoder(os.Stdout).Encode(resp)
		},
	}
	create.Flags().String("profile", "", "AWS profile name (required)")
	create.Flags().String("region", "", "AWS region (required)")
	_ = create.MarkFlagRequired("profile")
	_ = create.MarkFlagRequired("region")

	describe := &cobra.Command{
		Use:   "describe",
		Short: "Describe the current status of a stack refactor",
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")
			id, _ := cmd.Flags().GetString("id")

			resp, err := refactor.Describe(context.Background(), profile, region, id)
			if err != nil {
				return err
			}
			return json.NewEncoder(os.Stdout).Encode(resp)
		},
	}
	describe.Flags().String("profile", "", "AWS profile name (required)")
	describe.Flags().String("region", "", "AWS region (required)")
	describe.Flags().String("id", "", "Stack refactor ID (required)")
	_ = describe.MarkFlagRequired("profile")
	_ = describe.MarkFlagRequired("region")
	_ = describe.MarkFlagRequired("id")

	listActions := &cobra.Command{
		Use:   "list-actions",
		Short: "List the proposed actions of a stack refactor",
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")
			id, _ := cmd.Flags().GetString("id")

			actions, err := refactor.ListActions(context.Background(), profile, region, id)
			if err != nil {
				return err
			}
			return json.NewEncoder(os.Stdout).Encode(actions)
		},
	}
	listActions.Flags().String("profile", "", "AWS profile name (required)")
	listActions.Flags().String("region", "", "AWS region (required)")
	listActions.Flags().String("id", "", "Stack refactor ID (required)")
	_ = listActions.MarkFlagRequired("profile")
	_ = listActions.MarkFlagRequired("region")
	_ = listActions.MarkFlagRequired("id")

	execute := &cobra.Command{
		Use:   "execute",
		Short: "Execute a previously-created stack refactor (non-blocking)",
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")
			id, _ := cmd.Flags().GetString("id")

			if err := refactor.Execute(context.Background(), profile, region, id); err != nil {
				return err
			}
			return nil
		},
	}
	execute.Flags().String("profile", "", "AWS profile name (required)")
	execute.Flags().String("region", "", "AWS region (required)")
	execute.Flags().String("id", "", "Stack refactor ID (required)")
	_ = execute.MarkFlagRequired("profile")
	_ = execute.MarkFlagRequired("region")
	_ = execute.MarkFlagRequired("id")

	cmd.AddCommand(create, describe, listActions, execute)
	return cmd
}

func stacksCmd() *cobra.Command {
	cmd := &cobra.Command{Use: "stacks", Short: "CloudFormation stack queries"}

	list := &cobra.Command{
		Use:   "list",
		Short: "List CloudFormation stacks in the active account/region (excludes DELETE_COMPLETE)",
		RunE: func(cmd *cobra.Command, _ []string) error {
			profile, _ := cmd.Flags().GetString("profile")
			region, _ := cmd.Flags().GetString("region")

			summaries, err := stacks.List(context.Background(), profile, region)
			if err != nil {
				return err
			}
			if summaries == nil {
				summaries = []stacks.Summary{}
			}
			return json.NewEncoder(os.Stdout).Encode(summaries)
		},
	}
	list.Flags().String("profile", "", "AWS profile name (required)")
	list.Flags().String("region", "", "AWS region (required)")
	_ = list.MarkFlagRequired("profile")
	_ = list.MarkFlagRequired("region")

	cmd.AddCommand(list)
	return cmd
}
