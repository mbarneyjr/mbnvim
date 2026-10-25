{
  vimUtils,
}:
vimUtils.buildVimPlugin {
  pname = "agent-prompt.nvim";
  version = "0.0.0";
  src = ./.;
}
