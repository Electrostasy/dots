# dots
## `age` Key Rotation

The `age` private key is used for decrypting secrets encrypted with the public
key on activation. If the key is unavailable, you will not be able to login and
certain services will not function correctly.

The `age` private key has to be generated and placed in
`/var/lib/sops-nix/keys.txt` before secrets can be decrypted or rotated.
Generate the `age` private key:
```sh
rage-keygen -o ~/keys.txt
```

These commands can rotate the keys in all encrypted files in-place:
```sh
regex=$(regexes=($(rg 'path_regex: (.*)$' -Nor '$1' .sops.yaml)); IFS='|'; echo "(${regexes[*]})")
key="$(rg '# public key: (.*)' -or '$1' /var/lib/sops-nix/keys.txt)"
key_new="$(rg '# public key: (.*)' -or '$1' ~/keys.txt)"

fd --full-path "$regex" -x sops rotate -i --add-age "$key_new" --rm-age "$key"
```

> [!IMPORTANT]
> The public key in the `.sops.yaml` configuration file and the private key in
> `/var/lib/sops-nix/keys.txt` have to be updated manually.


# Installation
## deimos

This is a [Raspberry Pi Zero 2 W], running Klipper for my 3D printer.

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#deimos --image-variant raw
cp ./result/nixos-deimos* .
systemd-dissect --with nixos-deimos* install -D {,.}/var/lib/sops-nix/keys.txt
```

Due to the limitations of the [Raspberry Pi Zero 2 W], it does not support
booting from GPT directly, it needs an MBR or hybrid MBR image. Due to the
limitations of the NixOS module system, we cannot make this GPT image into a
hybrid MBR image without occasionally encountering infinite recursion errors.
[Convert](https://forums.raspberrypi.com/viewtopic.php?t=320299#p1920410) the
image into a hybrid MBR partitioning scheme manually:
```sh
sgdisk --typecode=1:0c01 --hybrid=1:EE nixos-deimos*
```

Flash the image to microSD card:
```sh
dd if=nixos-deimos* of=/dev/sdX bs=1M status=progress oflag=direct
```

[Raspberry Pi Zero 2 W]: https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/


## luna

This is a [Raspberry Pi Compute Module 4] mounted on an [Axzez Interceptor v1.0]
carrier board.

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#luna --image-variant raw
cp ./result/nixos-luna* .
systemd-dissect --with nixos-luna* install -D {,.}/var/lib/sops-nix/keys.txt
```

Flash the image to eMMC storage using the Raspberry Pi Compute Module 4 IO
Board:

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
   dd if=nixos-luna* of=/dev/sdX bs=1M status=progress oflag=direct
   ```
6. Disconnect the micro USB cable from the host PC.
7. Power off the IO Board.
8. Detach the CM4 and attach it to your carrier board.

For maintenance, when a disk fails or is near failing in the array, we need to
swap the disk out.

> [!CAUTION]
> You can only mount the array in degraded mode once or your data is lost!

If the disk is still visible in the system, we need to mount it degraded
(because btrfs tools work with mounted filesystems) in recovery mode and issue
a replace command:
```sh
mkdir -p /mnt/array
mount -t btrfs -o degraded /dev/disk/by-label/array /mnt/array
btrfs replace start /dev/disk/by-id/$FAILED /dev/disk/by-id/$NEW /mnt/array
```

If the disk is not visible in the system, we need to identify the missing disk
by its ID and provide it to the replace command:
```sh
btrfs filesystem show # check if there are missing devices.
btrfs device usage /mnt/array # identified by `missing, ID: $FAILED_ID`.
btrfs replace start $FAILED_ID /dev/disk/by-id/$NEW /mnt/array
```

Check the status of the replace operation:
```sh
btrfs replace status /mnt/array
```

After the replace operation finishes, balance the filesystem to ensure data is
evenly distributed between drives in the array:
```sh
btrfs balance start /mnt/array
```

[Raspberry Pi Compute Module 4]: https://www.raspberrypi.com/products/compute-module-4/?variant=raspberry-pi-cm4001000
[Axzez Interceptor v1.0]: https://www.axzez.com/product-page/interceptor-carrier-board


## hyperion

This is a Rockchip RK3576 based SBC - an [ArmSoM Sige5].

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

[ArmSoM Sige5]: https://docs.armsom.org/armsom-sige5


## mars

This is a Rockchip RK3588 based SBC - a [FriendlyElec NanoPC-T6 LTS].

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

[FriendlyElec NanoPC-T6 LTS]: https://wiki.friendlyelec.com/wiki/index.php/NanoPC-T6


## atlas

This is a Rockchip RK3588 based SBC - an [ArmSoM Sige7].

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

[ArmSoM Sige7]: https://docs.armsom.org/armsom-sige7


## mercury and terra

The hosts [mercury], a Asus ROG Flow Z13 (2022) laptop, and [terra], a desktop
PC, have an [erase-your-darlings] inspired encrypted btrfs root setup, where on
every boot the root subvolume is restored from an empty snapshot (accomplished
using a systemd service in the initrd).

1. Create the ESP, LUKS encrypted root and swap partitions:
   ```sh
   sgdisk -n 1::+1G -t 1:ef00 -n 2::-16G -t 2:8309 -n 3::0 -t 3:8200 /dev/nvme0n1
   cryptsetup luksFormat --uuid eea26205-2ae5-4d2c-9a13-32c7d9ae2421 /dev/nvme0n1p2
   cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
   ```
2. Format the partitions:
   ```sh
   mkfs.vfat -F 32 -n BOOT /dev/nvme0n1p1
   mkfs.btrfs -L nixos /dev/mapper/cryptroot
   mkswap -L swap /dev/nvme0n1p3
   ```
3. Set up the btrfs subvolumes and empty root snapshot:
   ```sh
   mount /dev/mapper/cryptroot -o compress-force=zstd:1,noatime /mnt
   btrfs subvolume create /mnt/{root,nix,persist,persist/{cache,state}}
   btrfs subvolume snapshot -r /mnt/{root,root-blank}
   umount /mnt
   ```
4. Prepare the mountpoints for installation:
   ```sh
   mount /dev/mapper/cryptroot -o subvol=root,compress-force=zstd:1,noatime /mnt
   mount /dev/mapper/cryptroot -o subvol=nix,compress-force=zstd:1,noatime -m /mnt/nix
   mount /dev/mapper/cryptroot -o subvol=persist,compress-force=zstd:1,noatime -m /mnt/persist
   mount /dev/nvme0n1p1 -m /mnt/boot
   ```
5. Download, build and install the NixOS configuration:
   ```sh
   git clone https://github.com/Electrostasy/dots /mnt/persist/state/etc/nixos
   # IMPORTANT: don't forget to copy the age private key:
   # install -D keys.txt /mnt/persist/state/var/lib/sops-nix/keys.txt
   nixos-install --flake /mnt/persist/state/etc/nixos#terra --root /mnt --no-root-passwd
   ```

[erase-your-darlings]: https://grahamc.com/blog/erase-your-darlings/
[mercury]: ./hosts/mercury/default.nix
[terra]: ./hosts/terra/default.nix


## phobos

This is a [Raspberry Pi 4 Model B], hosting various things like my VPN.

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#phobos --image-variant raw
cp ./result/nixos-phobos* .
systemd-dissect --with nixos-phobos* install -D {,.}/var/lib/sops-nix/keys.txt
```

Flash the image to microSD card:
```sh
dd if=nixos-phobos* of=/dev/sdX bs=1M status=progress oflag=direct
```

[Raspberry Pi 4 Model B]: https://www.raspberrypi.com/products/raspberry-pi-4-model-b/


# License

This project is licensed under the [MIT License](LICENSE), unless specified
otherwise.
