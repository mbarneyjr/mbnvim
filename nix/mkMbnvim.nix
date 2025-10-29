{ system, inputs }:

let
  pkgs = import inputs.nixpkgs {
    system = system;
    config = {
      allowUnfree = true;
    };
    overlays = import ./overlays;
  };
  plugins = with pkgs.vimPlugins; [
    # notify
    nvim-notify
    # fold
    nvim-ufo
    # colorscheme
    tokyonight-nvim
    # lualine
    lualine-nvim
    # which-key
    which-key-nvim
    # file handling
    bigfile-nvim
    hex-nvim
    # tmux
    vim-tmux-navigator
    # treesitter
    nvim-treesitter.withAllGrammars
    nvim-treesitter-textobjects
    nvim-ts-autotag
    # nvim-tree
    nvim-tree-lua
    nvim-web-devicons
    mini-icons
    # comment
    comment-nvim
    nvim-ts-context-commentstring
    # undotree
    undotree
    # telescope
    telescope-nvim
    telescope-fzf-native-nvim
    fzf-lua
    # harpoon
    harpoon2
    # images
    image-nvim
    # git
    vim-fugitive
    vim-rhubarb
    gitsigns-nvim
    vim-flog
    # code
    trouble-nvim
    nvim-coverage
    nvim-dap
    nvim-dap-view
    nvim-nio
    nvim-dap-virtual-text
    conform-nvim
    nvim-lint
    # language-specific tools
    tsc-nvim
    ts-error-translator
    # cmp, snippets
    blink-cmp
    blink-copilot
    luasnip
    # lsp
    nvim-lspconfig
    nvim-lsp-file-operations
    twoslash-queries
    # ai
    copilot-lua
    avante-nvim
    codecompanion-nvim
  ];
  extraPackages = [
    pkgs.sqlite
    pkgs.pngpaste
    pkgs.tree-sitter
    pkgs.imagemagick
    pkgs.lynx
    pkgs.terraform
    pkgs.fzf
    pkgs.stylua
    pkgs.nodePackages.prettier
    pkgs.black
    pkgs.usort
    pkgs.actionlint
    pkgs.tflint
    pkgs.terraform-ls
    pkgs.nixfmt-rfc-style
    pkgs.vscode-js-debug
    pkgs.typescript-language-server
    pkgs.biome
    pkgs.vscode-langservers-extracted
    pkgs.go
    pkgs.gopls
    pkgs.golangci-lint
    pkgs.lua-language-server
    pkgs.docker-language-server
    pkgs.dockerfile-language-server
    pkgs.docker-compose-language-service
    pkgs.dot-language-server
    pkgs.basedpyright
    pkgs.templ
    pkgs.nil
    pkgs.nixd
    pkgs.bash-language-server
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.tailwindcss-language-server
    pkgs.glsl_analyzer
    pkgs.python3Packages.cfn-lsp-extra
    pkgs.gh-actions-language-service
    pkgs.cedar-language-server
    pkgs.tmux-language-server
  ];
  extraLuaPackages = with pkgs.neovim-unwrapped.lua.pkgs; [
    magick
    tiktoken_core
    fzf-lua
  ];
  defaultPlugin = {
    plugin = null;
    config = null;
    optional = false;
    runtime = { };
  };
  normalizedPlugins = map (x: defaultPlugin // (if x ? plugin then x else { plugin = x; })) plugins;
  neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    viAlias = false;
    vimAlias = false;
    plugins = normalizedPlugins;
  };

  luaCPaths =
    pkgs.lib.concatMapStringsSep ";" pkgs.neovim-unwrapped.lua.pkgs.getLuaCPath
      extraLuaPackages;
  luaPaths =
    pkgs.lib.concatMapStringsSep ";" pkgs.neovim-unwrapped.lua.pkgs.getLuaPath
      extraLuaPackages;
  neovimBase = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (
    neovimConfig
    // {
      wrapperArgs = builtins.concatStringsSep " " [
        (pkgs.lib.escapeShellArgs neovimConfig.wrapperArgs)
        ''--prefix PATH : "${pkgs.lib.makeBinPath extraPackages}"''
        ''--set LIBSQLITE_CLIB_PATH "${pkgs.sqlite.out}/lib/libsqlite3.so"''
        ''--set LIBSQLITE "${pkgs.sqlite.out}/lib/libsqlite3.so"''
        ''--suffix LUA_CPATH ";" "${luaCPaths}"''
        ''--suffix LUA_PATH ";" "${luaPaths}"''
      ];
    }
  );

  initLua = pkgs.writeText "init.lua" ''
    vim.opt.rtp:prepend('${../.}')
    ${builtins.readFile ../init.lua}
  '';
in

pkgs.stdenvNoCC.mkDerivation {
  pname = "mbnvim";
  version = "1.0";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${neovimBase}/bin/nvim $out/bin/nvim \
      --set VIMINIT "lua dofile('${initLua}')"
  '';
}
