{ buildUBoot
, fetchFromGitHub
, armTrustedFirmwareRK3576
, rkbin
}:

buildUBoot {
  version = "0-unstable-2025-02-11";

  # TODO: Use upstream version if it ever gets merged:
  # https://patchwork.ozlabs.org/project/uboot/list/?series=433708
  src = fetchFromGitHub {
    owner = "Kwiboo";
    repo = "u-boot-rockchip";
    rev = "d9abdc3fc104a8852e819f97356f088a163cf0d6";
    hash = "sha256-r1gSd0FCw7VsQwLbjeHgYu+ve/gjqbiW7L5JExYxIxw=";
  };

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
  ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.08.bin";
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
