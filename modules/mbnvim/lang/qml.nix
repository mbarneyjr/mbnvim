{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.kdePackages.qtdeclarative
      ];
    };
}
