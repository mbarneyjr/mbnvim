{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.pyright
        pkgs.black
        pkgs.usort
      ];
    };
}
