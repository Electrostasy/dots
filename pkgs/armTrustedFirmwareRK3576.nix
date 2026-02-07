{
  buildArmTrustedFirmware,
}:

buildArmTrustedFirmware rec {
  extraMakeFlags = [ "bl31" ];
  platform = "rk3576";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error=unterminated-string-initialization";
}
