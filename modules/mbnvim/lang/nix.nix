{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.nil
        pkgs.nixd
        pkgs.nixfmt
      ];
    };
}
