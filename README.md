# dots

This repository contains a [Nix] [flake] for packages, [NixOS] modules &
configurations across my various devices. This README is to be considered
documentation for this flake and the managed devices.

The other sections describe what hosts are managed by this flake, the devices
they are deployed to, and, where necessary, building, imaging, flashing and
installation.

[Nix]: https://nixos.org/guides/how-nix-works.html
[flake]: https://nixos.wiki/wiki/Flakes
[NixOS]:https://nixos.org/guides/how-nix-works.html#nixos


## Hosts Overview

> [!CAUTION]
>
> These configurations contain encrypted secrets managed by [sops-nix] and care
> should be taken when building and activating them.
>
> Most of these configurations cannot be successfully activated on machines that
> do not have a `/var/lib/sops-nix/keys.txt` file containing the [`age`] private
> key corresponding to an `age` public key in the root [.sops.yaml] file.

The managed hosts and their descriptions are listed in the following table:

| **Hostname** | **Device type**               | **Description**                                |
|:--           | :--                           | :--                                            |
| ceres        | Desktop                       | Secondary PC at work                           |
| deimos       | Raspberry Pi Zero 2 W         | Klipper host for 3D printer                    |
| eris         | WSL                           | Primary PC at work                             |
| luna         | Raspberry Pi Compute Module 4 | NAS                                            |
| mars         | FriendlyElec NanoPC-T6 LTS    | -                                              |
| mercury      | Asus ROG Flow Z13 (2022)      | Personal/work laptop                           |
| phobos       | Raspberry Pi 4 Model B        | Dendrite Matrix homeserver </br> Headscale VPN |
| terra        | Desktop                       | Primary PC at home                             |
| venus        | Lenovo ThinkPad X230 Tablet   | Personal laptop                                |

[sops-nix]: https://github.com/Mic92/sops-nix
[`age`]: https://age-encryption.org/v1
[.sops.yaml]: ./.sops.yaml


## Key Rotation Notes

The `age` private key is used for decrypting secrets encrypted with the public
key on NixOS system activation. If the key is unavailable, you will not be able
to login and certain services will not function correctly. The `age` private key
has to be generated and placed in `/var/lib/sops-nix/keys.txt` before secrets
can be decrypted or rotated. The `age` private key can be generated using the
following command:

```sh
rage-keygen -o ~/keys.txt
```

In order to make key rotation easier, the following commands will re-encrypt all
secret files in this repository, when executed from its root, using the new key:

```sh
SECRET_FILES_REGEX=$(REGEXES=($(rg 'path_regex: (.*)$' -Nor '$1' .sops.yaml)); IFS='|'; echo "(${REGEXES[*]})")
AGE_PUBLIC_KEY="$(rg '# public key: (.*)' -or '$1' /var/lib/sops-nix/keys.txt)"
AGE_PUBLIC_KEY_NEW="$(rg '# public key: (.*)' -or '$1' ~/keys.txt)"

fd --full-path "$SECRET_FILES_REGEX" -x sops rotate -i --add-age "$AGE_PUBLIC_KEY_NEW" --rm-age "$AGE_PUBLIC_KEY"
```

The public key in the `.sops.yaml` configuration file and the
private key in `/var/lib/sops-nix/keys.txt` have to be updated manually.


# Installation Guides

This section contains installation guides and documentation for certain devices
managed by this flake, in the order of the table provided in the previous
section.

> [!IMPORTANT]
>
> Some of the following hosts can have images built for them, however, in order
> for NixOS activation to be successful, the `age` private key needs to be
> copied into the image:
>
> ```sh
> systemd-dissect --copy-to nixos-* {,}/var/lib/sops-nix/keys.txt
> ```


## deimos

The host [deimos] is a Raspberry Pi Zero 2 W, used for controlling the Original
Prusa MK3S+ 3D printer flashed with Klipper firmware. It serves a Mainsail web
interface for remote monitoring and management of the 3D printer.

[deimos]: ./hosts/deimos/default.nix


### Building the image

The NixOS SD image to be flashed can be built using the following command
(requires `aarch64-linux` platform):

```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#deimos --image-variant raw
```


### Flashing the image

The NixOS SD image may be flashed to a selected microSD card using the following
command:

```sh
dd if=nixos-deimos-*.img of=/dev/sdX bs=1M status=progress oflag=direct
```


## luna

The host [luna] is a Raspberry Pi Compute Module 4 (CM4) mounted to an [Axzez
Interceptor] carrier board, serving as Network Attached Storage.

[luna]: ./hosts/luna/default.nix
[Axzez Interceptor]: https://www.axzez.com/product-page/interceptor-carrier-board


### Building the image

The NixOS SD image to be flashed can be built using the following command
(requires `aarch64-linux` platform):

```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#luna --image-variant raw
```


### Flashing the image

The NixOS SD image may be flashed to eMMC storage using the Raspberry Pi Compute
Module 4 IO Board. The following is a set of steps in order to prepare the IO
Board for flashing the CM4:
1. Bridge the first set of pins on the 'J2' jumper to disable eMMC boot.
2. Connect the IO Board with the host PC you will flash from using a micro USB cable.
3. Power on the IO Board.
4. Run `rpiboot` on the host PC to see eMMC storage as a block device:

   ```sh
   rpiboot
   ```

5. Flash the image to it:

   ```sh
   dd if=nixos-luna-*.img of=/dev/sdX bs=1M status=progress oflag=direct
   ```

6. Disconnect the micro USB cable from the host PC.
7. Power off the IO Board.
8. Detach the CM4 and attach it to your carrier board.


## mars

The host [mars] is a [FriendlyElec NanoPC-T6 LTS], currently unused.

The preferred way would be to flash both `u-boot` and the NixOS image to SPI and
eMMC respectively, however, at the time of writing, due to [limitations] in
`rkdeveloptool`, the open-source command line flashing tool developed by
Rockchip as an alternative to the closed-source `upgrade_tool`, we cannot select
between SPI and eMMC flash memory when flashing. Because of this, we build an
installer image with `u-boot` included, and flash on the target system instead
of externally over USB.

[mars]: ./hosts/mars/default.nix
[FriendlyElec NanoPC-T6 LTS]: https://wiki.friendlyelec.com/wiki/index.php/NanoPC-T6
[limitations]: https://github.com/rockchip-linux/rkdeveloptool/issues/94


### Building the image

The NixOS installer SD image to be flashed can be built using the following
command (requires `aarch64-linux` platform):

```sh
NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild --impure --flake github:Electrostasy/dots#mars build-image --image-variant raw
```


### Flashing the image

The NixOS installer SD image may be flashed to a selected microSD card or USB
flash drive using the following command:

```sh
dd if=nixos-mars-*.img of=/dev/sdX bs=1M status=progress oflag=direct
```

Then, when it is booted, we can write `u-boot` to SPI flash and install NixOS to
eMMC memory. The `u-boot` build suitable for SPI flash, provided in
`u-boot-rockchip-spi.bin`, contains the miniloader `idbloader.img` and u-boot
proper `u-boot.itb` files concatenated at their expected offsets.

In order to flash `u-boot` to SPI on a running system, use the following
command:

```sh
flashcp -v -p u-boot-rockchip-spi.bin /dev/mtd0
```

In order to install NixOS to eMMC on a running system, you have to target
`/dev/mmcblk0` as the target installation device.


## mercury (and terra)

The host [mercury] (and [terra]) has an [erase-your-darlings] inspired
encrypted btrfs root setup, where on every boot the root subvolume is rolled
back to an empty snapshot. Rollbacks are accomplished using a systemd service
in the initrd.

### Partitioning

The below commands detail the partitioning process for the host [mercury]:

```sh
# Create 1G ESP, LUKS root and 16G swap partitions.
sgdisk -n 1::+1G -t 1:ef00 -n 2::-16G -t 2:8309 -n 3::0 -t 3:8200 /dev/nvme0n1

# Format the ESP.
mkfs.vfat -F 32 -n BOOT /dev/nvme0n1p1

# Format the root partition.
cryptsetup luksFormat --uuid eea26205-2ae5-4d2c-9a13-32c7d9ae2421 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
mkfs.btrfs -L nixos /dev/mapper/cryptroot

# Format the swap partition.
mkswap -L swap /dev/nvme0n1p3

# Set up the btrfs subvolumes.
mount /dev/mapper/cryptroot -o compress-force=zstd:1,noatime /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/state
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
umount /mnt
```

### Installation

The below commands detail the installation process for the host [mercury]:

```sh
mount /dev/mapper/cryptroot -o subvol=root,compress-force=zstd:1,noatime /mnt
mkdir -p /mnt/{nix,state,boot,var/log,var/lib/sops-nix,etc/nixos}

mount /dev/mapper/cryptroot -o subvol=nix,compress-force=zstd:1,noatime /mnt/nix
mount /dev/mapper/cryptroot -o subvol=state,compress-force=zstd:1,noatime /mnt/state
mount /dev/nvme0n1p1 /mnt/boot
mkdir -p /mnt/state/{var/log,var/lib/sops-nix,etc/nixos}
mount -o bind /mnt/state/var/log /mnt/var/log
# IMPORTANT: don't forget to populate /mnt/var/lib/sops-nix/keys.txt!
mount -o bind /mnt/state/var/lib/sops-nix /mnt/var/lib/sops-nix
mount -o bind /mnt/state/etc/nixos /mnt/etc/nixos

# Download the NixOS configuration to install into its directory.
git clone https://github.com/Electrostasy/dots /mnt/etc/nixos

nixos-install --flake /mnt/etc/nixos#mercury --root /mnt --no-root-passwd
```

[terra]: ./hosts/terra/default.nix
[mercury]: ./hosts/mercury/default.nix
[erase-your-darlings]: https://grahamc.com/blog/erase-your-darlings/


## phobos

The host [phobos] is a Raspberry Pi 4 Model B, used to host the dendrite Matrix
homeserver and the headscale coordination server for Tailscale VPN to link my
devices together.

[phobos]: ./hosts/phobos/default.nix


### Building the image

The NixOS SD image to be flashed can be built using the following command
(requires `aarch64-linux` platform):

```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#phobos --image-variant raw
```


### Flashing the image

Flash the SD image to a selected microSD card using the following command:

```sh
dd if=nixos-phobos-*.img of=/dev/sdX bs=1M status=progress oflag=direct
```
