{
  description = "Neovim derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          self',
          system,
          ...
        }:
        let
          mkMbnvim = import ./nix/mkMbnvim.nix;
        in
        {
          packages = {
            mbnvim = mkMbnvim {
              inherit system inputs;
            };
            default = self'.packages.mbnvim;
          };
          apps = {
            mbnvim = {
              type = "app";
              program = "${self'.packages.mbnvim}/bin/nvim";
            };
            default = self'.apps.mbnvim;
          };
        };
    };
}
