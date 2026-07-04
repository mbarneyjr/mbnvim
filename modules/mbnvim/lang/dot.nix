{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.dot-language-server
      ];
    };
}
