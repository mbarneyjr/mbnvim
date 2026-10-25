# { inputs, ... }:
{
  # flake.overlays.cedar-language-server = final: prev: {
  #   cedar-language-server = prev.rustPlatform.buildRustPackage {
  #     pname = "cedar";
  #     version = inputs.cedar.shortRev or "unstable";
  #     src = inputs.cedar;
  #     cargoHash = "sha256-1gmLRfq/D1WYfswCKAPwUm60JZ/Zl32l3knKKvfqTNk=";
  #     buildAndTestSubdir = "cedar-language-server";
  #   };
  # };
  #
  # perSystem =
  #   { pkgs, ... }:
  #   {
  #     mbnvim.extraPackages = [
  #       pkgs.cedar-language-server
  #     ];
  #   };
}
