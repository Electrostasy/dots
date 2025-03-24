{ buildArmTrustedFirmware
, fetchFromGitHub
}:

buildArmTrustedFirmware rec {
  version = "0-unstable-2025-02-25";

  src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "arm-trusted-firmware";
    # 2.12.1 does not contain the commit adding RK3576 support.
    rev = "04b2fb42b171e3fbf2ef823558ac5b0119663dc7";
    hash = "sha256-NMyy6xbtk1iCdeelaXcIjdwHxJJpi8IiFzLrqP6PidI=";
  };

  extraMakeFlags = [ "bl31" ];
  platform = "rk3576";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
}
