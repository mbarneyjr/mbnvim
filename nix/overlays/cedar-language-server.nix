final: prev: {
  cedar-language-server = prev.pkgs.rustPlatform.buildRustPackage {
    pname = "cedar";
    version = "0.10.0";
    src = prev.pkgs.fetchFromGitHub {
      owner = "cedar-policy";
      repo = "cedar";
      rev = "8c7fb87043bc65600f6f09c291dbde37ee670071";
      sha256 = "sha256-/amq3jU+dLgLXnnjCqqCL/WW1kerVtyA/+5yVa1BzIc=";
    };
    cargoHash = "sha256-hO8fHvJOGk1FOzm3o6bN+D+1Gdh6Yri6X9ZmGhZ1wTs=";
    buildAndTestSubdir = "cedar-language-server";
  };
}
