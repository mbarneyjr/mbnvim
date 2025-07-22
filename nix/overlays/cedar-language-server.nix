final: prev: {
  cedar-language-server = prev.pkgs.rustPlatform.buildRustPackage {
    pname = "cedar";
    version = "0.10.0";
    src = prev.pkgs.fetchFromGitHub {
      owner = "cedar-policy";
      repo = "cedar";
      rev = "1475ea3b1f79e2f14fb05e95aab0d51f0ea1af5a";
      sha256 = "sha256-ETYr7cKdrGenoPbZ/09vdY0sJzFPjk32KO/dwUOSlhc=";
    };
    cargoHash = "sha256-qDbVmmtDVd10jNmFTvVnji0yaMeEerVpMipe2gGsWP8=";
    buildAndTestSubdir = "cedar-language-server";
  };
}
