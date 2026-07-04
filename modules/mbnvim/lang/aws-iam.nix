{
  perSystem =
    { inputs', ... }:
    {
      mbnvim.extraPackages = [
        inputs'.aws-iam-language-server.packages.default
      ];
    };
}
