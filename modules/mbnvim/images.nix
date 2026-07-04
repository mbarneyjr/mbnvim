{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = [
          pkgs.vimPlugins.image-nvim
        ];
        extraPackages = [
          pkgs.imagemagick
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
          pkgs.pngpaste
        ];
        luaPackages = [
          pkgs.neovim-unwrapped.lua.pkgs.magick
        ];
      };
    };
}
