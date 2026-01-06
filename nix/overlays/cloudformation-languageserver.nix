final: prev: {
  cloudformation-languageserver = prev.stdenv.mkDerivation rec {
    pname = "cloudformation-languageserver";
    version = "1.2.0";

    src =
      let
        sources = {
          x86_64-linux = {
            url = "https://github.com/aws-cloudformation/cloudformation-languageserver/releases/download/v${version}/cloudformation-languageserver-${version}-linux-x64-node22.zip";
            sha256 = "";
          };
          aarch64-linux = {
            url = "https://github.com/aws-cloudformation/cloudformation-languageserver/releases/download/v${version}/cloudformation-languageserver-${version}-linux-arm64-node22.zip";
            sha256 = "";
          };
          x86_64-darwin = {
            url = "https://github.com/aws-cloudformation/cloudformation-languageserver/releases/download/v${version}/cloudformation-languageserver-${version}-darwin-x64-node22.zip";
            sha256 = "";
          };
          aarch64-darwin = {
            url = "https://github.com/aws-cloudformation/cloudformation-languageserver/releases/download/v${version}/cloudformation-languageserver-${version}-darwin-arm64-node22.zip";
            sha256 = "sha256-bQWXccAVOVZhJCzySjUpieGS7997xreMQYgG9iOfiiw=";
          };
        };
        source =
          sources.${prev.stdenv.hostPlatform.system}
            or (throw "Unsupported system: ${prev.stdenv.hostPlatform.system}");
      in
      prev.fetchzip {
        inherit (source) url sha256;
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
                       "const dir = '~/.local/state/cloudformation-languageserver'"

      mkdir -p $out/bin
      makeWrapper ${prev.nodejs}/bin/node $out/bin/cfn-lsp-server-standalone \
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
