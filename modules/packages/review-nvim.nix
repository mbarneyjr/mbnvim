{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        review-nvim-vim-plugin = pkgs.callPackage ../../packages/review.nvim/vimPlugin.nix { };
        review-nvim-claude-plugin = pkgs.callPackage ../../packages/review.nvim/claudePlugin.nix { };
      };
    };
}
