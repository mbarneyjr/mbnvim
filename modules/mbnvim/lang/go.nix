{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.go
        pkgs.gopls
        pkgs.golangci-lint
        pkgs.templ
      ];
    };
}
