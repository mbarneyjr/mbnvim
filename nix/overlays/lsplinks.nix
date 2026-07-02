inputs: final: prev: {
  vimPlugins = prev.vimPlugins // {
    lsplinks = prev.vimUtils.buildVimPlugin {
      pname = "lsplinks-nvim";
      version = inputs.lsplinks-nvim.shortRev or "unstable";
      src = inputs.lsplinks-nvim;
    };
  };
}
