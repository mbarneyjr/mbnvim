{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.bash-language-server
        pkgs.shellcheck
        pkgs.shfmt
      ];
    };
}
