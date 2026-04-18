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
      name = "0001-HACK-mkimage-fit-Keep-data-that-should-be-loaded-into-SRAM-embedded.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/aaa15f13dfa8a563c57feb4bb35b6a0bf3a59640.patch";
      hash = "sha256-HZLP+PWkd1rWNXon51NJb45rWh84lyStref0e+Fp50o=";
    })
    (fetchpatch {
      name = "0002-usb-tcpm-improve-handling-of-some-power-supplies.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/cba06ef9d3660e970de7661d0949ca59e2420f28.patch";
      hash = "sha256-Vk3OVco558nGOsLHbb53OCNRwF0fORICEJnqv9zXAGQ=";
    })
    (fetchpatch {
      name = "0003-usb-tcpm-avoid-resets-for-missing-source-capability-messages.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/ce3707801d2a17ef30b35762e24cc05909c16fde.patch";
      hash = "sha256-I4+A/Vdz5T6XbsFgDS/41j2UJEC1Bbjlz27XyFDvAH0=";
    })
    (fetchpatch {
      name = "0004-usb-tcpm-print-error-on-hard-reset.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/0a4d214a771ae060135b9a50993f7556d77cc5db.patch";
      hash = "sha256-BVKyL4GyiY72sugbamSpkJk8hoplUGTT4wzph+1TSVA=";
    })
    (fetchpatch {
      name = "0005-usb-tcpm-improve-data-role-mismatch-error-recovery.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/b1bcfadcf705ff9814af7f391205cb959028eab7.patch";
      hash = "sha256-FB8Q3J7mN/xbXyyed4CTX/EazEhwbXuvw9cJvcXLI54=";
    })
    (fetchpatch {
      name = "0006-usb-tcpm-improve-unsupported-control-message-error.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/158c0fd5a03d099a87ba05aae0058fcb3f68b041.patch";
      hash = "sha256-HlQMFnxb3Z2qc9Br3f5jVttPYC1cesNMsCL5fRp1vEU=";
    })
    (fetchpatch {
      name = "0007-usb-tcpm-fusb302-add-missing-newline-character-to-debug-output.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/77b7a315f1477b83c53870c98fe4ca646fd0f57a.patch";
      hash = "sha256-d3sf2+rextiBRzDY8mB4OKE8OBNYZ6yTyOV6F6n8uv4=";
    })
    (fetchpatch {
      name = "0008-usb-tcpm-fusb302-add-support-for-set_vbus-callback.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/c41dc4e6fba3c729784c322240bb7a531eefdbad.patch";
      hash = "sha256-H2zJehJDUQeMLxmQXGl/Rvdske8dpT3KOy4V3UV76Xw=";
    })
    (fetchpatch {
      name = "0009-usb-tcpm-fix-toggling-in-host-SRC-mode.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/40a726b763afe1c4bd368df5fc81a15c7d582933.patch";
      hash = "sha256-uDlbMbPHJmBbq1h/xzNh8N++F5YcGYhE3ndj3PttJ5E=";
    })
    (fetchpatch {
      name = "0010-usb-tcpm-fix-pd_transmit-poll-condition.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/123172981b815d92d5f243b26f4ba488c38485ba.patch";
      hash = "sha256-4JrioIirroGgYmW499UYsaawFgrTt9Olc4lorZ0raTQ=";
    })
    (fetchpatch {
      name = "0011-board-rockchip-add-fusb302-node-on-Sige5.patch";
      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/commit/e6ba1712228ae074c252844bb65c69bd2aa544a3.patch";
      hash = "sha256-sZ+zFwjDQR5XESgr+m5gUiT69GzUSgbymnCe2IHAWQA=";
    })

    # Mainline U-Boot cannot be booted on RK3576 boards without these patches, see:
    # https://patchwork.ozlabs.org/project/uboot/patch/20250627025721.962397-1-liujianfeng1994@gmail.com/
    # https://patchwork.ozlabs.org/project/uboot/cover/20260311-rk3576-ufs-v6-0-c7c353739242@flipper.net/
    (fetchpatch {
      name = "0012-rockchip_mkimage_Split_size_and_off_and_size_and_nimage.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/117cd97627fd79bd00eba03157a7350dacbe22aa.patch";
      hash = "sha256-3KpB+kNfKNhOQLOmeHn/3PGdxzLc/m6teqF5K3P7Qik=";
    })
    (fetchpatch {
      name = "0013-rockchip-mkimage-Print-image-information-for-all-embedded-images.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/6ea000250906951008e4c96e6c2d3f1cbec7a0cf.patch";
      hash = "sha256-T4uCA0xwgMqmqLcoElVbnghTujWMINe7NpC/bvMiOEA=";
    })
    (fetchpatch {
      name = "0014-rockchip-mkimage-Print-boot0-and-boot1-parameters.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/105c9261a443df63e95728fcbf6c9ec29233df4b.patch";
      hash = "sha256-O+BcYosfFaAHv5lj8mljY93rP4KfDFSDrpsD9I4edR8=";
    })
    (fetchpatch {
      name = "0015-rockchip-mkimage-Add-option-to-change-image-offset-alignment.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/581802b28df537c33413c4adc45e5a7bedd846e4.patch";
      hash = "sha256-nfS2T6WsXnLoPJSBD1fkRJE9IzfXOTVkfWBCdY4BQ6U=";
    })
    (fetchpatch {
      name = "0016-rockchip-mkimage-Add-support-for-up-to-4-input-files.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/bbb89db9da039c54694898e0d4df8c79237c4d3e.patch";
      hash = "sha256-j7liHVOVFfASfCoqL7IC4xEoVb/LuJvEP/uX6S9Du5Q=";
    })
    (fetchpatch {
      name = "0017-rockchip-mkimage-Add-option-for-image-load-address-and-flag.patch";
      url = "https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commit/9dd8239119975642696bf1f4a2a48507f4dfe805.patch";
      hash = "sha256-+h6WqdwDb5YpV6G2eN+d4pJUjt+WmOAmhMOzUZQ7YBg=";
    })
    (fetchpatch {
      name = "0018-WIP-rockchip-mkimage-Add-rk3576-align-and-sd-card-workaround.patch";
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
