{
  buildUBoot,
  fetchpatch,
  armTrustedFirmwareRK3576,
  rkbin,
}:

buildUBoot {
  # https://patchwork.ozlabs.org/project/uboot/patch/20250627025721.962397-1-liujianfeng1994@gmail.com/
  patches = [
    (fetchpatch {
      # https://patchwork.ozlabs.org/cover/2040406/
      name = "0001-rockchip-mkimage-Improve-support-for-v2-image-format.patch";
      url = "https://patchwork.ozlabs.org/series/442233/mbox/";
      hash = "sha256-YQWX8EuIt9tku9RxEFMm3JqnOIAkEK+1nQOghjJq79I=";
    })
    (fetchpatch {
      name = "0002-WIP-rockchip-mkimage-Add-rk3576-align-and-sd-card-workaround.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/d43031c4045ef8aaf29c467b910207e721dabce0.patch";
      hash = "sha256-CO3Au6EoowZnSKx6aECSdzaVdHreiXz0j3qrt6YMFcY=";
    })
    (fetchpatch {
      name = "0003-board-rockchip-add-fusb302-node-on-Sige5.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/e6ba1712228ae074c252844bb65c69bd2aa544a3.patch";
      hash = "sha256-sZ+zFwjDQR5XESgr+m5gUiT69GzUSgbymnCe2IHAWQA=";
    })
  ];

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
  ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.09.bin";
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
