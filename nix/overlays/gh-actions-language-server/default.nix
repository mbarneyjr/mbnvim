final: prev:
let
  src = prev.fetchFromGitHub {
    owner = "actions";
    repo = "languageservices";
    rev = "cc316ab9dea2d77763691fd3d7cd5e120fe15724";
    hash = "sha256-21di43NuUEa/EQydwbhIYRpeGoWN0oRgRBeRuxZ+AlU=";
  };

  jq = prev.lib.getExe prev.jq;

  # Generate a complete package-lock.json with all resolved URLs and integrity
  # hashes. The upstream lock file is missing these for many packages, which
  # breaks nix's npm fetcher. This FOD has network access so npm can resolve
  # everything properly.
  packageLock = prev.stdenv.mkDerivation {
    name = "actions-languageserver-package-lock.json";
    inherit src;
    nativeBuildInputs = [
      prev.nodejs
      prev.jq
      prev.cacert
    ];
    SSL_CERT_FILE = "${prev.cacert}/etc/ssl/certs/ca-bundle.crt";
    outputHash = "sha256-3hawKw/REPE1qIqVnQihahnhXBN00HzezT+JLyBiCUM=";
    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    dontInstall = true;
    buildPhase = ''
      ${jq} 'del(.devDependencies["rest-api-description"])' languageservice/package.json > tmp.json && mv tmp.json languageservice/package.json
      rm package-lock.json
      export HOME=$TMPDIR
      npm install --package-lock-only
      cp package-lock.json $out
    '';
  };
in
{
  actions-languageserver = prev.buildNpmPackage {
    name = "actions-languageserver";
    inherit src;
    nativeBuildInputs = [ prev.jq ];
    postPatch = ''
      cp ${packageLock} ./package-lock.json
      ${jq} 'del(.devDependencies["rest-api-description"])' languageservice/package.json > tmp.json && mv tmp.json languageservice/package.json
    '';
    npmDepsHash = "sha256-VT2ogGL+ZYNbUJuqxA8dCHkX1PRDnsiz9usYzFgLTwY=";
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
