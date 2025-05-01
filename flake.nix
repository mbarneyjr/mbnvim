{
  description = "Neovim derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      ...
    }:
    let
      mkMbnvim = import ./nix/mkMbnvim.nix;
    in
    {
      packages.aarch64-darwin.default = mkMbnvim {
        system = "aarch64-darwin";
        inputs = inputs;
      };
      apps.aarch64-darwin.default = {
        type = "app";
        program = "${self.packages.aarch64-darwin.default}/bin/nvim";
      };
    };
}
