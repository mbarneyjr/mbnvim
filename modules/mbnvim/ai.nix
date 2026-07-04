{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = with pkgs.vimPlugins; [
          copilot-lua
        ];
        extraPackages = [
          pkgs.copilot-language-server
        ];
      };
    };
}
