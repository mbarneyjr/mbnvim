{
  nodejs_24,
  buildNpmPackage,
  writeShellScriptBin,
  writeText,
  runCommand,
}:
let
  mcp = buildNpmPackage {
    name = "review-nvim-mcp";
    version = "1.0.0";
    src = ./.;
    nodejs = nodejs_24;
    npmDepsHash = "sha256-0bwp9EPoQK/9jg7unQSx5WxCnWL+G/gBkc0qYHG1xqM=";
    dontNpmBuild = true;
    postInstall = ''
      mv $out/lib/node_modules/review.nvim $out/lib/review-nvim
      rmdir $out/lib/node_modules
    '';
  };
  mcpBin = writeShellScriptBin "review-nvim-mcp" ''
    exec ${nodejs_24}/bin/node ${mcp}/lib/review-nvim/src/index.ts "$@"
  '';
  mcpJson = writeText ".mcp.json" (builtins.toJSON {
    mcpServers = {
      "review.nvim" = {
        command = "\${CLAUDE_PLUGIN_ROOT}/bin/review-nvim-mcp";
      };
    };
  });
in
runCommand "review-nvim-claude-plugin" { } ''
  mkdir -p $out/.claude-plugin $out/skills $out/bin

  cp ${./.claude-plugin/plugin.json} $out/.claude-plugin/plugin.json
  cp ${mcpJson} $out/.mcp.json
  cp -r ${./skills}/* $out/skills/
  ln -s ${mcpBin}/bin/review-nvim-mcp $out/bin/review-nvim-mcp
''
