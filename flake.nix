{
  description = "Neovim derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    cfn-lsp-extra = {
      url = "github:LaurenceWarne/cfn-lsp-extra";
      flake = false;
    };
    twoslash-queries-src = {
      url = "github:marilari88/twoslash-queries.nvim";
      flake = false;
    };
    ts-error-translator-src = {
      url = "github:dmmulroy/ts-error-translator.nvim";
      flake = false;
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
