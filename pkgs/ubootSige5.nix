{
  buildUBoot,
  fetchurl,
  armTrustedFirmwareRK3576,
  rkbin,
}:

buildUBoot {
  patches = [
    # Mainline U-Boot cannot be booted on RK3576 boards without these patches, see:
    # https://patchwork.ozlabs.org/project/uboot/patch/20250627025721.962397-1-liujianfeng1994@gmail.com/
    # https://patchwork.ozlabs.org/project/uboot/cover/20260311-rk3576-ufs-v6-0-c7c353739242@flipper.net/
    # [0/7] rockchip: fix boot from SDMMC on RK3576
    # https://patchwork.ozlabs.org/cover/2269849
    (fetchurl {
      name = "0001-1-7-rockchip-mkimage-Split-size_and_off-and-size_and_nimage.diff";
      url = "https://patchwork.ozlabs.org/patch/2269850/raw";
      hash = "sha256-lVmXjW8cBdFGsd81nOyzvK/MsmIqi4VmH7bngY5Jahs=";
    })
    (fetchurl {
      name = "0002-2-7-rockchip-mkimage-Print-image-information-for-all-embedded-images.diff";
      url = "https://patchwork.ozlabs.org/patch/2269851/raw";
      hash = "sha256-ZVCurOfalQ+AI41J0VwVHiWq1mxFL8itum/FBxoR+nI=";
    })
    (fetchurl {
      name = "0003-3-7-rockchip-mkimage-Print-boot0-and-boot1-parameters.diff";
      url = "https://patchwork.ozlabs.org/patch/2269853/raw";
      hash = "sha256-sn4T/1ST/8Tjg65CwgoQuFpjOdDG71zlWwcmABrVKFo=";
    })
    (fetchurl {
      name = "0004-4-7-rockchip-mkimage-Add-option-to-change-image-offset-alignment.diff";
      url = "https://patchwork.ozlabs.org/patch/2269854/raw";
      hash = "sha256-NvKoof5qPE4SAJcjHuf6ObLDj+i+l/tjoJ15VowF90A=";
    })
    (fetchurl {
      name = "0005-5-7-rockchip-mkimage-Add-support-for-up-to-4-input-files.diff";
      url = "https://patchwork.ozlabs.org/patch/2269855/raw";
      hash = "sha256-8kmGhs89KR/M4rKaTBrWdsHZeQBigqjH7seANOEq1RE=";
    })
    (fetchurl {
      name = "0006-6-7-rockchip-mkimage-Add-option-for-image-load-address-and-flag.diff";
      url = "https://patchwork.ozlabs.org/patch/2269856/raw";
      hash = "sha256-WUw01N1pLyh9uMSnb0M3RCR7O9RZLVczuQiYsn5G3N8=";
    })
    (fetchurl {
      name = "0007-7-7-rockchip-mkimage-Add-rk3576-align-and-sd-card-workaround.diff";
      url = "https://patchwork.ozlabs.org/patch/2269857/raw";
      hash = "sha256-7cxU4iyZryzzPaDA4fVBAjLZWokFgNyYHj8QpkJy0zg=";
    })
  ];

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  env = {
    BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
    ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.12.bin";
  };
  filesToInstall = [
    "u-boot.itb"
    "idbloader.img"
    "u-boot-rockchip.bin"
  ];
}
