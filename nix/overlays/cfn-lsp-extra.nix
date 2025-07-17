{ cfn-lsp-extra }:
final: prev: {
  python3Packages = prev.python3Packages // {
    cfn-lsp-extra = final.python3Packages.buildPythonApplication {
      pname = "cfn-lsp-extra";
      version = "0.7.4";
      src = cfn-lsp-extra;
      pyproject = true;
      build-system = [
        prev.python3Packages.poetry-core
        prev.python3Packages.poetry-dynamic-versioning
      ];

      propagatedBuildInputs = [
        final.python3Packages.pyyaml
        final.python3Packages.attrs
        final.python3Packages.aws-sam-translator
        final.python3Packages.botocore
        final.python3Packages.cfn-lint
        final.python3Packages.click
        final.python3Packages.importlib-resources
        final.python3Packages.platformdirs
        final.python3Packages.pygls
        final.python3Packages.types-pyyaml
      ];

      patchPhase = ''
        substituteInPlace pyproject.toml \
          --replace 'aws-sam-translator (>=1.96.0)' 'aws-sam-translator' \
          --replace 'cfn-lint (>=1.32.4,<2.0.0)' 'cfn-lint'
      '';

      doCheck = false;
    };
  };
}
