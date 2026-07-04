{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = with pkgs.vimPlugins; [
          vim-fugitive
          vim-rhubarb
          gitsigns-nvim
          vim-flog
        ];
        extraPackages = [
          pkgs.git
        ];
      };
    };
}
