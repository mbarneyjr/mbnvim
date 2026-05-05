{
  vimUtils,
  buildGoModule,
}:
let
  cfntool = buildGoModule {
    pname = "cfntool";
    version = "0.0.0";
    src = ./helper;
    vendorHash = "sha256-YgTwUKAidarYzoFkdpnlgFVfldmP++deCuSXQQCHzcU=";
    subPackages = [ "cmd/cfntool" ];
  };
in
vimUtils.buildVimPlugin {
  pname = "cfn.nvim";
  version = "0.0.0";
  src = ./.;
  postInstall = ''
    mkdir -p $out/bin
    cp ${cfntool}/bin/cfntool $out/bin/cfntool
  '';
}
