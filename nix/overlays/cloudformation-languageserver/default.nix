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
          currentSystemSrc =
            sources.${prev.stdenv.hostPlatform.system}
              or (throw "Unsupported system: ${prev.stdenv.hostPlatform.system}");
        in
        prev.fetchzip {
          inherit (currentSystemSrc) url sha256;
          stripRoot = false;
        };
      dontFixup = true;
      nativeBuildInputs = [ prev.makeWrapper ];
      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib/${pname}
        cp -r . $out/lib/${pname}/
        mkdir -p $out/bin
        makeWrapper ${prev.nodejs}/bin/node $out/bin/cfn-lsp-server \
          --add-flags "$out/lib/${pname}/cfn-lsp-server-standalone.js"
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
