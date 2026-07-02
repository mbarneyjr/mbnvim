inputs: final: prev: {
  cedar-language-server = prev.pkgs.rustPlatform.buildRustPackage {
    pname = "cedar";
    version = inputs.cedar.shortRev or "unstable";
    src = inputs.cedar;
    cargoHash = "sha256-8OABa3HKP0NV1RMnbCTclXBUeSGabEzXsnwKo0i4mLw=";
    buildAndTestSubdir = "cedar-language-server";
  };
}
