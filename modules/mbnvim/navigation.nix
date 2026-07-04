{
  perSystem =
    { inputs', pkgs, ... }:
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
