{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.docker-language-server
        pkgs.dockerfile-language-server
        pkgs.docker-compose-language-service
      ];
    };
}
