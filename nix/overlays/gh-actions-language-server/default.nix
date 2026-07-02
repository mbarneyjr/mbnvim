inputs: final: prev:
let
  src = inputs.actions-languageservices;

  jq = prev.lib.getExe prev.jq;
in
{
  actions-languageserver = prev.buildNpmPackage {
    name = "actions-languageserver";
    inherit src;
    nativeBuildInputs = [ prev.jq ];
    postPatch = ''
      cp ${./package-lock.json} ./package-lock.json
      ${jq} 'del(.devDependencies["rest-api-description"])' languageservice/package.json > tmp.json && mv tmp.json languageservice/package.json
    '';
    npmDepsHash = "sha256-pm4kmXTE2zoCKvxjgo98b8tQitdU8S/myt0U10nLSa4=";
    npmBuildFlags = [ "--workspaces" ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules/@actions/languageserver
      cp -r languageserver/bin languageserver/dist languageserver/package.json $out/lib/node_modules/@actions/languageserver/
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@actions/languageserver/bin/actions-languageserver $out/bin/actions-languageserver
      runHook postInstall
    '';
  };
}
