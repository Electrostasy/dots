# Installation guides for Rockchip devices

This document contains installation guides for the following Rockchip devices:
- [ArmSoM Sige5](https://docs.armsom.org/armsom-sige5)
- [ArmSoM Sige7](https://docs.armsom.org/armsom-sige7)
- [FriendlyElec NanoPC-T6 LTS](https://wiki.friendlyelec.com/wiki/index.php/NanoPC-T6)


## ArmSoM Sige5
### hyperion

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#hyperion --image-variant raw
cp ./result/nixos-hyperion* .
systemd-dissect --with nixos-hyperion* install -D {,.}/var/lib/sops-nix/keys.txt
```

Change Storage functionality does not seem to work correctly on RK3576, so we
first flash U-Boot to microSD separately and then the image to eMMC storage
using `rkdeveloptool`:

1. Build the U-Boot firmware and flash it to microSD:
   ```sh
   nix build github:Electrostasy/dots#legacyPackages.aarch64-linux.ubootSige5
   dd if=./result/u-boot-rockchip.bin of=/dev/sdX bs=32k seek=1 conv=fsync
   ```
2. Insert the microSD with flashed U-Boot firmware into the board.
3. Enter MaskROM mode on the board by holding down the MaskROM and power
   buttons; after the status LED has been on for at least 3 seconds, the
   MaskROM and power buttons may be released.
4. Connect the board and the host PC you will flash from with a USB cable.
5. Run the following command on the host PC to verify a MaskROM device is
   connected:
   ```sh
   rkdeveloptool ld
   ```
6. Get the Rockchip proprietary SPL bootloader blobs and download the loader to
   the board:
   ```sh
   NIXPKGS_ALLOW_UNFREE=1 nix build --impure nixpkgs#rkboot
   rkdeveloptool db ./result/bin/rk3576_spl_loader_v*.bin
   ```
7. Select eMMC memory as storage and flash the NixOS image to it:
   ```sh
   rkdeveloptool cs 1
   rkdeveloptool ef
   rkdeveloptool wl 0 nixos-hyperion*
   ```
8. Reboot the device:
   ```sh
   rkdeveloptool rd
   ```
9. Disconnect the USB cable from the board and the host PC.


## ArmSoM Sige7
### atlas

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#atlas --image-variant raw
cp ./result/nixos-atlas* .
systemd-dissect --with nixos-atlas* install -D {,.}/var/lib/sops-nix/keys.txt
```

First ensure the board's microSD card slot is populated, then flash U-Boot to
microSD and the image to eMMC storage using `rkdeveloptool`:

1. Enter MaskROM mode on the board by holding down the MaskROM and power
   buttons; after the status LED has been on for at least 3 seconds, the
   MaskROM and power buttons may be released.
2. Connect the board and the host PC you will flash from with a USB cable.
3. Run the following command on the host PC to verify a MaskROM device is
   connected:
   ```sh
   rkdeveloptool ld
   ```
4. Get the Rockchip proprietary SPL bootloader blobs and download the loader to
   the board:
   ```sh
   NIXPKGS_ALLOW_UNFREE=1 nix build --impure nixpkgs#rkboot
   rkdeveloptool db ./result/bin/rk3588_spl_loader_v*.bin
   ```
5. Build the U-Boot firmware, then select SD as storage and flash it:
   ```sh
   nix build github:Electrostasy/dots#legacyPackages.aarch64-linux.ubootSige7
   rkdeveloptool cs 2
   rkdeveloptool ef
   rkdeveloptool wl 64 ./result/u-boot-rockchip.bin
   ```
6. Select eMMC memory as storage and flash the NixOS image to it:
   ```sh
   rkdeveloptool cs 1
   rkdeveloptool ef
   rkdeveloptool wl 0 nixos-atlas*
   ```
7. Reboot the device:
   ```sh
   rkdeveloptool rd
   ```
8. Disconnect the USB cable from the board and the host PC.


## FriendlyElec NanoPC-T6 LTS
### mars

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#mars --image-variant raw
cp ./result/nixos-mars* .
systemd-dissect --with nixos-mars* install -D {,.}/var/lib/sops-nix/keys.txt
```

Flash U-Boot to SPI NOR flash and the image to eMMC storage using
`rkdeveloptool`:

1. Enter MaskROM mode on the board by holding down the MaskROM and power
   buttons; after the status LED has been on for at least 3 seconds, the
   MaskROM and power buttons may be released.
2. Connect the board and the host PC you will flash from with a USB-C cable.
3. Run the following command on the host PC to verify a MaskROM device is
   connected:
   ```sh
   rkdeveloptool ld
   ```
4. Get the Rockchip proprietary SPL bootloader blobs and download the loader to
   the board:
   ```sh
   NIXPKGS_ALLOW_UNFREE=1 nix build --impure nixpkgs#rkboot
   rkdeveloptool db ./result/bin/rk3588_spl_loader_v*.bin
   ```
5. Build the U-Boot firmware, then select SPI NOR flash as storage and flash
   it:
   ```sh
   nix build nixpkgs#legacyPackages.aarch64-linux.ubootNanoPCT6
   rkdeveloptool cs 9
   rkdeveloptool ef
   rkdeveloptool wl 0 ./result/u-boot-rockchip-spi.bin
   ```
6. Select eMMC memory as storage and flash the NixOS image to it:
   ```sh
   rkdeveloptool cs 1
   rkdeveloptool ef
   rkdeveloptool wl 0 nixos-mars*
   ```
7. Reboot the device:
   ```sh
   rkdeveloptool rd
   ```
8. Disconnect the USB-C cable from the board and the host PC.
