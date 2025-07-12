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
      # https://patchwork.ozlabs.org/cover/2110229/
      name = "0001-rockchip-rk3576-Add-rng-checkboard-and-generic-board.patch";
      url = "https://patchwork.ozlabs.org/series/464855/mbox/";
      hash = "sha256-8zBU9GVQYVP0t+vkcXliosPR8FRonyTMkE+Sz/Aky5M=";
    })
    (fetchpatch {
      # https://patchwork.ozlabs.org/cover/2110236/
      name = "0002-board-rockchip-Add-ArmSoM-Sige5.patch";
      url = "https://patchwork.ozlabs.org/series/464856/mbox/";
      hash = "sha256-vxpMBAj9wWTqd9JfRLarQu1tjnJyJSFwR9TTti0Bms0=";
    })
    (fetchpatch {
      # https://patchwork.ozlabs.org/cover/2040406/
      name = "0003-rockchip-mkimage-Improve-support-for-v2-image-format.patch";
      url = "https://patchwork.ozlabs.org/series/442233/mbox/";
      hash = "sha256-YQWX8EuIt9tku9RxEFMm3JqnOIAkEK+1nQOghjJq79I=";
    })
    (fetchpatch {
      name = "0004-WIP-rockchip-mkimage-Add-rk3576-align-and-sd-card-workaround.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/0f059fd91a8590261270d0ec29e94fc17defdd51.patch";
      hash = "sha256-Yk5TLdaR7nM8sQbKMsU9yjn4+ixy40a5kUnBeQGxsGE=";
    })
    (fetchpatch {
      name = "0005-board-rockchip-add-fusb302-node-on-Sige5.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/4dd07d2a54a03ec6ee84d4f4db0d327fbf7f228a.patch";
      hash = "sha256-TmXqM8UL+N5NIpsrFPL4DQ1X2GrBmW+rnQzX36ITZAs=";
    })
  ];

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
  ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.09.bin";
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
