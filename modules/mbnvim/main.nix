{
  perSystem =
    {
      lib,
      config,
      pkgs,
      self',
      ...
    }:
    let
      cfg = config.mbnvim;
      luaEnv = pkgs.neovim-unwrapped.lua.pkgs;
      luaCPaths = pkgs.lib.concatMapStringsSep ";" luaEnv.getLuaCPath cfg.luaPackages;
      luaPaths = pkgs.lib.concatMapStringsSep ";" luaEnv.getLuaPath cfg.luaPackages;
      neovimBase =
        (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
          withNodeJs = true;
          withRuby = true;
          withPython3 = true;
          viAlias = false;
          vimAlias = false;
          plugins = cfg.plugins;
          wrapRc = false;
          wrapperArgs = [
            "--prefix"
            "PATH"
            ":"
            "${pkgs.lib.makeBinPath cfg.extraPackages}"
          ]
          ++ pkgs.lib.concatLists (
            pkgs.lib.mapAttrsToList (name: value: [
              "--set"
              name
              value
            ]) cfg.wrapperEnv
          )
          ++ [
            "--suffix"
            "LUA_CPATH"
            ";"
            "${luaCPaths}"
            "--suffix"
            "LUA_PATH"
            ";"
            "${luaPaths}"
          ];
        }).overrideAttrs
          { dontStrip = true; };

      initLua = pkgs.writeText "init.lua" ''
        vim.opt.rtp:prepend('${../../.}')
        ${builtins.readFile ../../init.lua}
      '';
    in
    {
      options.mbnvim = {
        plugins = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Vim plugins bundled into mbnvim.";
        };
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Packages prefixed onto mbnvim's PATH.";
        };
        luaPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Lua packages added to LUA_PATH/LUA_CPATH.";
        };
        wrapperEnv = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Environment variables set on the nvim wrapper.";
        };
      };

      config = {
        packages = {
          mbnvim = pkgs.stdenvNoCC.mkDerivation {
            pname = "mbnvim";
            version = "1.0";
            nativeBuildInputs = [ pkgs.makeWrapper ];
            dontUnpack = true;
            dontFixup = true;
            installPhase = ''
              mkdir -p $out/bin
              makeWrapper ${neovimBase}/bin/nvim $out/bin/nvim \
                --set VIMINIT "lua dofile('${initLua}')"
            '';
          };
          default = pkgs.symlinkJoin {
            name = "mbnvim-full";
            paths = [
              self'.packages.mbnvim
              self'.packages.review-nvim-claude-plugin
            ];
          };
        };
      };
    };
}
