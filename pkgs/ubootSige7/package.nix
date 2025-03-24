{ buildUBoot
, armTrustedFirmwareRK3588
, rkbin
}:

buildUBoot {
  extraPatches = [
    # Required to negotiate 5-12V PD over USB-C (otherwise it will be stuck at
    # 5V), based on:
    # https://github.com/Joshua-Riek/ubuntu-rockchip/pull/677.
    ./0001-Enable-ArmSoM-Sige7-Early-PD-Negotiation.patch
  ];

  defconfig = "sige7-rk3588_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3588}/bl31.elf";
  ROCKCHIP_TPL = rkbin.TPL_RK3588;
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
