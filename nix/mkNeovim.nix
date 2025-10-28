{
  lib,
  sqlite,
  neovim-unwrapped,
  wrapNeovimUnstable,
  neovimUtils,
}:
with lib;
{
  plugins ? [ ],
  extraPackages ? [ ],
  extraLuaPackages ? p: [ ],
}:
let
  defaultPlugin = {
    plugin = null;
    config = null;
    optional = false;
    runtime = { };
  };
  normalizedPlugins = map (x: defaultPlugin // (if x ? plugin then x else { plugin = x; })) plugins;

  neovimConfig = neovimUtils.makeNeovimConfig {
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    viAlias = true;
    vimAlias = true;
    plugins = normalizedPlugins;
  };

  resolvedExtraLuaPackages = extraLuaPackages neovim-unwrapped.lua.pkgs;
  luaCPaths = concatMapStringsSep ";" neovim-unwrapped.lua.pkgs.getLuaCPath resolvedExtraLuaPackages;
  luaPaths = concatMapStringsSep ";" neovim-unwrapped.lua.pkgs.getLuaPath resolvedExtraLuaPackages;
in
# wrapNeovimUnstable is the nixpkgs utility function for building a Neovim derivation.
wrapNeovimUnstable neovim-unwrapped (
  neovimConfig
  // {
    luaRcContent = ''
      vim.opt.rtp:prepend('${../.}')
      ${builtins.readFile ../init.lua}
    '';
    wrapperArgs = builtins.concatStringsSep " " [
      (escapeShellArgs neovimConfig.wrapperArgs)
      ''--prefix PATH : "${makeBinPath extraPackages}"''
      ''--set LIBSQLITE_CLIB_PATH "${sqlite.out}/lib/libsqlite3.so"''
      ''--set LIBSQLITE "${sqlite.out}/lib/libsqlite3.so"''
      ''--suffix LUA_CPATH ";" "${luaCPaths}"''
      ''--suffix LUA_PATH ";" "${luaPaths}"''
    ];
    wrapRc = true;
  }
)
