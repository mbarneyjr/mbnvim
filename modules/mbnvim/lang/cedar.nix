{ inputs, ... }:
{
  flake.overlays.cedar-language-server = final: prev: {
    cedar-language-server = prev.rustPlatform.buildRustPackage {
      pname = "cedar";
      version = inputs.cedar.shortRev or "unstable";
      src = inputs.cedar;
      cargoHash = "sha256-8OABa3HKP0NV1RMnbCTclXBUeSGabEzXsnwKo0i4mLw=";
      buildAndTestSubdir = "cedar-language-server";
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.cedar-language-server
      ];
    };
}
