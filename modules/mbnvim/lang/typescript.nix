{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = [
          pkgs.vimPlugins.tsc-nvim
        ];
        extraPackages = [
          pkgs.typescript-language-server
          pkgs.vscode-js-debug
          pkgs.biome
        ];
      };
    };
}
