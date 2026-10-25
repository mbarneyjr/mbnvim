{
  perSystem =
    { pkgs, ... }:
    {
      packages.agent-prompt-nvim = pkgs.callPackage ../../packages/agent-prompt.nvim/vimPlugin.nix { };
    };
}
