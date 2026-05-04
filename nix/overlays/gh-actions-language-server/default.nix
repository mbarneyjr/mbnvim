final: prev:
let
  src = prev.fetchFromGitHub {
    owner = "actions";
    repo = "languageservices";
    rev = "cc316ab9dea2d77763691fd3d7cd5e120fe15724";
    hash = "sha256-21di43NuUEa/EQydwbhIYRpeGoWN0oRgRBeRuxZ+AlU=";
  };

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
    npmDepsHash = "sha256-SkgAdJQ87nA5OUGRzbg5Dh+6xFgS+hZNeqJoVb2U8mU=";
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
