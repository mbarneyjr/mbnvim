final: prev: {
  python3Packages = prev.python3Packages // {
    cfn-lint = (
      prev.python3Packages.cfn-lint.overridePythonAttrs (old: rec {
        version = "1.44.0";
        src = prev.fetchFromGitHub {
          owner = "aws-cloudformation";
          repo = "cfn-lint";
          tag = "v${version}";
          hash = "sha256-5Y2MxaZHH2c+VhwfUUzSSGnC1G1FRB7uin/r6JAJBjA=";
        };
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          prev.python3Packages.setuptools
        ];
        patchPhase = ''
          substituteInPlace pyproject.toml --replace-fail '"setuptools >= 80.10.2"' '"setuptools"'
        '';
        doCheck = false;
      })
    );
  };
}
