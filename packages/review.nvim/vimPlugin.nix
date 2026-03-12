{
  vimUtils,
}:
vimUtils.buildVimPlugin {
  pname = "review.nvim";
  version = "0.0.0";
  src = ./.;
}
