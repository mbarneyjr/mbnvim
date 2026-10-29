{ inputs, ... }:
{
  perSystem =
    { pkgs, inputs', ... }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./cfn-lint; };
      pythonSet =
        (pkgs.callPackage inputs.pyproject-nix.build.packages { python = pkgs.python313; }).overrideScope
          (
            pkgs.lib.composeManyExtensions [
              inputs.pyproject-build-systems.overlays.default
              (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
            ]
          );
      cfn-lint = pythonSet.mkVirtualEnv "cfn-lint-environment" workspace.deps.default;
    in
    {
      mbnvim.plugins = [
        inputs'.cfn-nvim.packages.vim-plugin
      ];
      mbnvim.extraPackages = [
        cfn-lint
        pkgs.aws-cloudformation-languageserver
        inputs'.cfn-nvim.packages.cfn-nvim
      ];
    };
}
