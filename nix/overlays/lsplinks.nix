final: prev: {
  vimPlugins = prev.vimPlugins // {
    lsplinks = prev.vimUtils.buildVimPlugin {
      pname = "lsplinks-nvim";
      version = "2025-03-26";
      src = prev.fetchFromGitHub {
        owner = "icholy";
        repo = "lsplinks.nvim";
        rev = "94d729170e95298ce86ba41ef66f8756f6062b34";
        sha256 = "0rx0556br7mngfa2khlkfcw34cwsybdp23zq03w76hd3vqhfvgx3";
      };
    };
  };
}
