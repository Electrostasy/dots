{ buildArmTrustedFirmware
, fetchFromGitHub
}:

buildArmTrustedFirmware rec {
  # 2.12.1 currently packaged upstream does not have RK3576 support.
  version = "2.13.0";

  src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "arm-trusted-firmware";
    tag = "v${version}";
    hash = "sha256-rxm5RCjT/MyMCTxiEC8jQeFMrCggrb2DRbs/qDPXb20=";
  };

  extraMakeFlags = [ "bl31" ];
  platform = "rk3576";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
}
