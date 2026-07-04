{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.opentofu
        pkgs.tflint
        pkgs.tofu-ls
      ];
    };
}
