{
  buildUBoot,
  fetchFromGitLab,
  armTrustedFirmwareRK3576,
  rkbin,
}:

buildUBoot {
  version = "0-unstable-2025-07-08";

  src = fetchFromGitLab {
    domain = "gitlab.collabora.com";
    owner = "hardware-enablement/rockchip-3588";
    repo = "u-boot";
    rev = "eaadfde0c6a8975c85d9da9e19a5af70795cd1c6";
    hash = "sha256-/7kFYtKkZwbhMVxfRXTQZgRWrOpswkvUHHYmcRhk2Mc=";
  };

  patches = [ ];

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
  ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.09.bin";
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
