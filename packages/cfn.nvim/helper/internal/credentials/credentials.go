package credentials

import (
	"bufio"
	"context"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

func defaultDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".aws")
}

func configFile() string {
	if v := os.Getenv("AWS_CONFIG_FILE"); v != "" {
		return v
	}
	return filepath.Join(defaultDir(), "config")
}

func credentialsFile() string {
	if v := os.Getenv("AWS_SHARED_CREDENTIALS_FILE"); v != "" {
		return v
	}
	return filepath.Join(defaultDir(), "credentials")
}

func ListProfiles() ([]string, error) {
	seen := make(map[string]struct{})
	addFromFile := func(path string, isConfig bool) error {
		f, err := os.Open(path)
		if err != nil {
			if os.IsNotExist(err) {
				return nil
			}
			return err
		}
		defer f.Close()
		s := bufio.NewScanner(f)
		for s.Scan() {
			line := strings.TrimSpace(s.Text())
			if !strings.HasPrefix(line, "[") || !strings.HasSuffix(line, "]") {
				continue
			}
			section := strings.TrimSpace(line[1 : len(line)-1])
			name := ""
			if isConfig {
				if section == "default" {
					name = "default"
				} else if strings.HasPrefix(section, "profile ") {
					name = strings.TrimSpace(strings.TrimPrefix(section, "profile "))
				}
			} else {
				name = section
			}
			if name != "" {
				seen[name] = struct{}{}
			}
		}
		return s.Err()
	}
	if err := addFromFile(configFile(), true); err != nil {
		return nil, err
	}
	if err := addFromFile(credentialsFile(), false); err != nil {
		return nil, err
	}
	out := make([]string, 0, len(seen))
	for name := range seen {
		out = append(out, name)
	}
	sort.Strings(out)
	return out, nil
}

type Resolved struct {
	AccessKeyID     string
	SecretAccessKey string
	SessionToken    string
	Region          string
	Account         string
	Expiry          string
}

func Resolve(ctx context.Context, profile, regionOverride string) (*Resolved, error) {
	opts := []func(*config.LoadOptions) error{
		config.WithSharedConfigProfile(profile),
	}
	if regionOverride != "" {
		opts = append(opts, config.WithRegion(regionOverride))
	}
	cfg, err := config.LoadDefaultConfig(ctx, opts...)
	if err != nil {
		return nil, err
	}
	creds, err := cfg.Credentials.Retrieve(ctx)
	if err != nil {
		return nil, err
	}
	stsClient := sts.NewFromConfig(cfg)
	identity, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		return nil, err
	}
	r := &Resolved{
		AccessKeyID:     creds.AccessKeyID,
		SecretAccessKey: creds.SecretAccessKey,
		SessionToken:    creds.SessionToken,
		Region:          cfg.Region,
		Account:         aws.ToString(identity.Account),
	}
	if creds.CanExpire {
		r.Expiry = creds.Expires.UTC().Format(time.RFC3339)
	}
	return r, nil
}
