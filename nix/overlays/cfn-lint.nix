final: prev: {
  python3Packages = prev.python3Packages // {
    cfn-lint = (
      prev.python3Packages.cfn-lint.overridePythonAttrs (old: rec {
        version = "1.51.2";
        src = prev.fetchFromGitHub {
          owner = "aws-cloudformation";
          repo = "cfn-lint";
          tag = "v${version}";
          hash = "sha256-IfBm/4kfYa+Let62hXTlwyrAM8sp+FN1vV6LOTLdQX0=";
        };
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          prev.python3Packages.setuptools
        ];
        patchPhase = ''
          substituteInPlace pyproject.toml --replace-fail '"setuptools >= 80.10.2"' '"setuptools"'
          substituteInPlace requirements/base.txt --replace-fail 'aws-sam-translator>=1.110.0' 'aws-sam-translator'
        '';
        doCheck = false;
      })
    );
  };
}
