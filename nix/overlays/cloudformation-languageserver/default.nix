final: prev: {
  cloudformation-languageserver =
    let
      sources = builtins.fromJSON (builtins.readFile ./sources.json);
    in
    prev.stdenv.mkDerivation rec {
      pname = "cloudformation-languageserver";
      version = sources.version;
      src =
        let
          # 3. Pick the source for the current system
          currentSystemSrc =
            sources.${prev.stdenv.hostPlatform.system}
              or (throw "Unsupported system: ${prev.stdenv.hostPlatform.system}");
        in
        prev.fetchzip {
          inherit (currentSystemSrc) url sha256;
          stripRoot = false;
        };

      nativeBuildInputs = [ prev.makeWrapper ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/${pname}
        cp -r . $out/lib/${pname}/

        # Patch the standalone.js file to use a fixed directory
        substituteInPlace $out/lib/${pname}/cfn-lsp-server-standalone.js \
          --replace-fail "const dir = (0, path_1.resolve)(__dirname);" \
                         "const dir = process.env.HOME + '/.local/state/cloudformation-languageserver'"

        mkdir -p $out/bin
        makeWrapper ${prev.nodejs}/bin/node $out/bin/cfn-lsp-server \
          --add-flags "$out/lib/${pname}/cfn-lsp-server-standalone.js" \
          --run 'export CFN_LSP_STORAGE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/cloudformation-languageserver"'

        runHook postInstall
      '';

      meta = with prev.lib; {
        description = "CloudFormation Language Server";
        homepage = "https://github.com/aws-cloudformation/cloudformation-languageserver";
        license = licenses.asl20;
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        maintainers = [ ];
      };
    };
}
