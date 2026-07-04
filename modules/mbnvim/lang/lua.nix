{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.lua-language-server
        pkgs.stylua
      ];
    };
}
