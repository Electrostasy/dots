{
  buildUBoot,
  fetchurl,
  fetchpatch,
  armTrustedFirmwareRK3576,
  rkbin,
}:

buildUBoot {
  version = "2026.01";
  src = fetchurl {
    url = "https://ftp.denx.de/pub/u-boot/u-boot-2026.01.tar.bz2";
    hash = "sha256-tg1YZc79vHXajaQVbFbEWOAN51pJuAwaLlipbjCtDVQ=";
  };

  patches = [
    (fetchpatch {
      name = "0001-board-rockchip-add-fusb302-node-on-Sige5.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/e6ba1712228ae074c252844bb65c69bd2aa544a3.patch";
      hash = "sha256-sZ+zFwjDQR5XESgr+m5gUiT69GzUSgbymnCe2IHAWQA=";
    })

    # Mainline U-Boot cannot be booted on RK3576 boards without these patches, see:
    # https://patchwork.ozlabs.org/project/uboot/patch/20250627025721.962397-1-liujianfeng1994@gmail.com/
    # https://patchwork.ozlabs.org/project/uboot/cover/20260311-rk3576-ufs-v6-0-c7c353739242@flipper.net/
    (fetchpatch {
      name = "0002-rockchip_mkimage_Split_size_and_off_and_size_and_nimage.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/117cd97627fd79bd00eba03157a7350dacbe22aa.patch";
      hash = "sha256-3KpB+kNfKNhOQLOmeHn/3PGdxzLc/m6teqF5K3P7Qik=";
    })
    (fetchpatch {
      name = "0003-rockchip-mkimage-Print-image-information-for-all-embedded-images.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/6ea000250906951008e4c96e6c2d3f1cbec7a0cf.patch";
      hash = "sha256-T4uCA0xwgMqmqLcoElVbnghTujWMINe7NpC/bvMiOEA=";
    })
    (fetchpatch {
      name = "0004-rockchip-mkimage-Print-boot0-and-boot1-parameters.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/105c9261a443df63e95728fcbf6c9ec29233df4b.patch";
      hash = "sha256-O+BcYosfFaAHv5lj8mljY93rP4KfDFSDrpsD9I4edR8=";
    })
    (fetchpatch {
      name = "0005-rockchip-mkimage-Add-option-to-change-image-offset-alignment.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/581802b28df537c33413c4adc45e5a7bedd846e4.patch";
      hash = "sha256-nfS2T6WsXnLoPJSBD1fkRJE9IzfXOTVkfWBCdY4BQ6U=";
    })
    (fetchpatch {
      name = "0006-rockchip-mkimage-Add-support-for-up-to-4-input-files.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/bbb89db9da039c54694898e0d4df8c79237c4d3e.patch";
      hash = "sha256-j7liHVOVFfASfCoqL7IC4xEoVb/LuJvEP/uX6S9Du5Q=";
    })
    (fetchpatch {
      name = "0007-rockchip-mkimage-Add-option-for-image-load-address-and-flag.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/9dd8239119975642696bf1f4a2a48507f4dfe805.patch";
      hash = "sha256-+h6WqdwDb5YpV6G2eN+d4pJUjt+WmOAmhMOzUZQ7YBg=";
    })
    (fetchpatch {
      name = "0008-WIP-rockchip-mkimage-Add-rk3576-align-and-sd-card-workaround.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/04e6417226f50e4e3cb04272280922eb425c18ab.patch";
      hash = "sha256-1fR4c/55IjmDGi7tD12ldnHK1sUiXcGsfedqq+oKa/8=";
    })
  ];

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
  ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.09.bin";
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
