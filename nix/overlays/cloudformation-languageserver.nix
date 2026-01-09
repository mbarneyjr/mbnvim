final: prev: {
  cloudformation-languageserver =
    let
      src = prev.fetchFromGitHub {
        owner = "aws-cloudformation";
        repo = "cloudformation-languageserver";
        rev = "3e40d97e5214c5217ce6fa68bbeb9bc8ff2c1e0d";
        hash = "sha256-19i0aHknzWaTTweCd68qI6nkn7qtGvydBhi9urlyCjw=";
      };
    in
    prev.buildNpmPackage {
      pname = "cloudformation-languageserver";
      version = (builtins.fromJSON (builtins.readFile "${src}/package.json")).version;
      inherit src;
      npmDepsHash = "sha256-wYN3V1bIXeZfnXrI5xI0SdGO/duj87dtsJ8k2hzKGpM=";
      npmInstallFlags = [ "--include=dev" ];
      npmPruneFlags = [ "--include=dev" ];
      npmPackFlags = [ "--include=dev" ];

      nativeBuildInputs = [ prev.makeWrapper ];

      postPatch = ''
        substituteInPlace webpack.config.js \
          --replace-fail "execSync('npm ci --omit=dev'" "console.log('[Nix] Skipping npm ci'" \
          --replace-fail "execSync(\`npm install --save-exact" "console.log(\`[Nix] Skipping npm install" \
          --replace-fail "execSync(\`npm rebuild" "console.log(\`[Nix] Skipping npm rebuild"
      '';

      postBuild = ''
        npm run bundle:prod
      '';

      postInstall = ''
        rm -rf $out/lib/node_modules
        mkdir -p $out/lib/cloudformation-languageserver
        cp -r bundle/production/* $out/lib/cloudformation-languageserver/
        cp -r node_modules $out/lib/cloudformation-languageserver/
        substituteInPlace $out/lib/cloudformation-languageserver/cfn-lsp-server-standalone.js \
          --replace-fail "const dir = (0, path_1.resolve)(__dirname);" \
                         "const dir = '/tmp/.local/state/cloudformation-languageserver'"

        mkdir -p $out/bin
        makeWrapper ${prev.nodejs}/bin/node $out/bin/cfn-lsp-server \
          --add-flags "$out/lib/cloudformation-languageserver/cfn-lsp-server-standalone.js"
      '';
    };
}
