## Installation guides

This document contains installation guides for the following devices:
- Raspberry Pi single-board computers:
  - [Raspberry Pi 4 Model B]
  - [Raspberry Pi Zero 2 W]
  - [Raspberry Pi Compute Module 4]
- Rockchip-based single-board computers:
  - [ArmSoM Sige5]
  - [ArmSoM Sige7]
  - [FriendlyElec NanoPC-T6 LTS]


## Building the image

Build the image on an `aarch64-linux` platform and insert the `age` private
key (replace `$HOST` with the desired system):
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#$HOST --image-variant default
cp ./result/nixos-* .
systemd-dissect --with nixos-* install -D {,.}/var/lib/sops-nix/keys.txt
```


## Flashing the image
### Raspberry Pi 4 Model B
### Raspberry Pi Zero 2 W

Flash the image to microSD card:
```sh
dd if=nixos-* of=/dev/sdX bs=1M status=progress oflag=direct
```


### Raspberry Pi Compute Module 4

Flash the image to eMMC storage using the [Raspberry Pi Compute Module 4 IO
Board]:

1. Bridge the first set of pins on the 'J2' jumper to disable eMMC boot.
2. Connect the IO Board with the host PC you will flash from using a micro USB
   cable.
3. Power on the IO Board.
4. Run `rpiboot` on the host PC to see eMMC storage as a block device:
   ```sh
   rpiboot
   ```
5. Flash the image to it:
   ```sh
   dd if=nixos-* of=/dev/sdX bs=1M status=progress oflag=direct
   ```
6. Disconnect the micro USB cable from the host PC.
7. Power off the IO Board.
8. Detach the CM4 and attach it to your carrier board.

### ArmSoM Sige5

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
   rkdeveloptool wl 0 nixos-*
   ```
8. Reboot the device:
   ```sh
   rkdeveloptool rd
   ```
9. Disconnect the USB cable from the board and the host PC.


### ArmSoM Sige7

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
   rkdeveloptool wl 0 nixos-*
   ```
7. Reboot the device:
   ```sh
   rkdeveloptool rd
   ```
8. Disconnect the USB cable from the board and the host PC.


### FriendlyElec NanoPC-T6 LTS

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
   rkdeveloptool wl 0 nixos-*
   ```
7. Reboot the device:
   ```sh
   rkdeveloptool rd
   ```
8. Disconnect the USB-C cable from the board and the host PC.


[Raspberry Pi 4 Model B]: https://www.raspberrypi.com/products/raspberry-pi-4-model-b/
[Raspberry Pi Zero 2 W]: https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/
[Raspberry Pi Compute Module 4]: https://www.raspberrypi.com/products/compute-module-4/?variant=raspberry-pi-cm4001000
[Raspberry Pi Compute Module 4 IO Board]: https://www.raspberrypi.com/products/compute-module-4-io-board/
[ArmSoM Sige5]: https://docs.armsom.org/armsom-sige5
[ArmSoM Sige7]: https://docs.armsom.org/armsom-sige7
[FriendlyElec NanoPC-T6 LTS]: https://wiki.friendlyelec.com/wiki/index.php/NanoPC-T6
