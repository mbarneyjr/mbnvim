final: prev: {
  gh-actions-language-service = prev.buildNpmPackage rec {
    name = "gh-actions-language-service";
    src = prev.fetchFromGitHub {
      owner = "lttb";
      repo = "gh-actions-language-server";
      rev = "0287d3081d7b74fef88824ca3bd6e9a44323a54d";
      hash = "sha256-ZWO5G33FXGO57Zca5B5i8zaE8eFbBCrEtmwwR3m1Px4=";
    };
    # this is a bun project, I've generated the package-lock myself:
    postPatch = ''
      cp ${./package-lock.json} ./package-lock.json
    '';
    npmDepsHash = "sha256-nTZlKH3PcVY3fk9vL3+8/fKmCK6Lxkhr+Eh+cJqIJj4=";
    npmBuildScript = "build:node";
    nativeBuildInputs = [
      prev.bun
    ];
  };
}
