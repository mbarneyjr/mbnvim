{
  perSystem =
    { self', ... }:
    {
      mbnvim.plugins = [
        self'.packages.review-nvim-vim-plugin
      ];
    };
}
