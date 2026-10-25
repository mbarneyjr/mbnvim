{
  perSystem =
    { self', ... }:
    {
      mbnvim.plugins = [
        self'.packages.agent-prompt-nvim
      ];
    };
}
