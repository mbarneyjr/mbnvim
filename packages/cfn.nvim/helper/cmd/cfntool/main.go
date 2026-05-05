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
)

func main() {
	root := &cobra.Command{
		Use:           "cfntool",
		Short:         "Helper binary for cfn.nvim",
		SilenceUsage:  true,
		SilenceErrors: true,
	}

	root.AddCommand(jweCmd())
	root.AddCommand(credentialsCmd())
	root.AddCommand(changesetCmd())

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
