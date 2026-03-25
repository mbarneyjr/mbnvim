{
  description = "Neovim derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    fff-nvim = {
      url = "github:dmtrKovalenko/fff.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aws-iam-language-server = {
      url = "github:mbarneyjr/aws-iam-language-server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
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
            review-nvim-vim-plugin = pkgs.callPackage ./packages/review.nvim/vimPlugin.nix { };
            review-nvim-claude-plugin = pkgs.callPackage ./packages/review.nvim/claudePlugin.nix { };
            mbnvim = mkMbnvim {
              inherit system inputs;
              aws-iam-language-server = inputs.aws-iam-language-server.packages.${system}.default;
              fff-nvim-plugin = inputs.fff-nvim.packages.${system}.fff-nvim;
              review-nvim-plugin = self'.packages.review-nvim-vim-plugin;
            };
            default = pkgs.symlinkJoin {
              name = "mbnvim-full";
              paths = [
                self'.packages.mbnvim
                self'.packages.review-nvim-claude-plugin
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
