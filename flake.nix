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
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = import ./nix/overlays;
          };
        in
        {
          packages = {
            mbnvim = mkMbnvim {
              inherit system inputs;
            };
            review-nvim-mcp = pkgs.review-nvim-mcp;
            default = pkgs.symlinkJoin {
              name = "mbnvim-full";
              paths = [
                self'.packages.mbnvim
                self'.packages.review-nvim-mcp
              ];
            };
          };
          apps = {
            mbnvim = {
              type = "app";
              program = "${self'.packages.mbnvim}/bin/nvim";
            };
            default = self'.apps.mbnvim;
          };
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.nodejs_24
            ];
          };
        };
    };
}
