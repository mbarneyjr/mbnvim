{ inputs, ... }:
{
  flake.overlays.cedar-language-server = final: prev: {
    cedar-language-server = prev.rustPlatform.buildRustPackage {
      pname = "cedar";
      version = inputs.cedar.shortRev or "unstable";
      src = inputs.cedar;
      cargoHash = "sha256-gXPBdkO5PhrmkDeTVJoUFQK5ESJ3KiaxIzHL+c7ZxrM=";
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
