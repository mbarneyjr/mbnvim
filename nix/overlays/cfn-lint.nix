inputs: final: prev: {
  python3Packages = prev.python3Packages // {
    cfn-lint = (
      prev.python3Packages.cfn-lint.overridePythonAttrs (old: {
        src = inputs.cfn-lint;
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
