{ inputs, ... }:
{
  flake.overlays.gh-review-nvim = final: prev: {
    vimPlugins = prev.vimPlugins // {
      gh-review-nvim = prev.vimUtils.buildVimPlugin {
        pname = "gh-review.nvim";
        version = inputs.gh-review-nvim.shortRev or "unstable";
        src = inputs.gh-review-nvim;
      };
    };
  };
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = with pkgs.vimPlugins; [
          vim-fugitive
          vim-rhubarb
          gitsigns-nvim
          vim-flog
          gh-review-nvim
        ];
        extraPackages = [
          pkgs.git
          pkgs.gh
        ];
      };
    };
}
