{
  perSystem =
    { inputs', pkgs, ... }:
    let
      nvim-tree-lua = pkgs.vimUtils.buildVimPlugin {
        pname = "nvim-tree.lua";
        version = "1.18.0-unstable-2026-08-04";
        src = pkgs.fetchFromGitHub {
          owner = "nvim-tree";
          repo = "nvim-tree.lua";
          rev = "b2aadda94b107480c48e548d6db51c6840b7b33c";
          hash = "sha256-ILF6IGHYy32tfOnhD4mUVneQXQz2PlaARahJQzJAwsQ=";
        };
        meta.homepage = "https://github.com/nvim-tree/nvim-tree.lua/";
      };
    in
    {
      mbnvim.plugins = with pkgs.vimPlugins; [
        # nvim-tree
        nvim-tree-lua
        nvim-web-devicons
        mini-icons
        # fuzzy finder
        inputs'.fff-nvim.packages.fff-nvim
      ];
    };
}
