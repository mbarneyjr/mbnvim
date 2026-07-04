{
  perSystem =
    { self', ... }:
    {
      apps = {
        mbnvim = {
          type = "app";
          program = "${self'.packages.mbnvim}/bin/nvim";
        };
        default = self'.apps.mbnvim;
      };
    };
}
