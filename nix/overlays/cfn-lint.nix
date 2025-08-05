final: prev: {
  python3Packages = prev.python3Packages // {
    cfn-lint = (
      prev.python3Packages.cfn-lint.overridePythonAttrs (old: rec {
        version = "1.38.1";
        src = prev.fetchFromGitHub {
          owner = "aws-cloudformation";
          repo = "cfn-lint";
          tag = "v${version}";
          hash = "sha256-/tGL0WmSNK/TKJYCNG9TjfRKQPGWMIp+HwiCchnoPLM=";
        };
        patchPhase = ''
          substituteInPlace pyproject.toml --replace "aws-sam-translator>=1.97.0" "aws-sam-translator"
        '';
        doCheck = false;
      })
    );
  };
}
