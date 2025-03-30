{ buildUBoot
, fetchFromGitLab
, armTrustedFirmwareRK3576
, rkbin
}:

buildUBoot {
  version = "0-unstable-2025-04-29";

  # TODO: Switch to upstream whenever support lands.
  # U-Boot does not yet have a stable release with RK3576 SoC support, but
  # Collabora have a lot of convenient patches on top of upstream's
  # v2025.07-rc1 (including patches sent and not yet sent to the mailing list,
  # like ArmSoM Sige5 board support:
  # https://patchwork.ozlabs.org/project/uboot/list/?series=453774).
  src = fetchFromGitLab {
    domain = "gitlab.collabora.com";
    owner = "hardware-enablement/rockchip-3588";
    repo = "u-boot";
    rev = "667bbdc907027bddacb8916428677c1db2e084e6";
    hash = "sha256-05m0vrXlHXohVx25Js7qrhHEl4qzhivwRyw9aUY33Ds=";
  };

  patches = [ ];

  defconfig = "sige5-rk3576_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  BL31 = "${armTrustedFirmwareRK3576}/bl31.elf";
  ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3576_ddr_lp4_2112MHz_lp5_2736MHz_v1.08.bin";
  filesToInstall = [ "u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" ];
}
