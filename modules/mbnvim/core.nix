{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = with pkgs.vimPlugins; [
          # misc
          snacks-nvim
          # notify
          nvim-notify
          # fold
          nvim-ufo
          # csv
          csvview-nvim
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
          # undotree
          undotree
          # telescope (kept for commands picker)
          telescope-nvim
          telescope-fzf-native-nvim
          # harpoon
          harpoon2
        ];
        extraPackages = [
          pkgs.gcc
          pkgs.ripgrep
          pkgs.fd
          pkgs.curl
          pkgs.sqlite
          pkgs.lynx
          pkgs.fzf
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          pkgs.wl-clipboard
          pkgs.xclip
        ];
        wrapperEnv = {
          LIBSQLITE_CLIB_PATH = "${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";
          LIBSQLITE = "${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";
        };
      };
    };
}
