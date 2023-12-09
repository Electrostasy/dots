# dots
This repository contains a [Nix] [flake] for packages, [NixOS] modules &
configurations across my various devices.

[Nix]: https://nixos.org/guides/how-nix-works.html
[flake]: https://nixos.wiki/wiki/Flakes
[NixOS]: https://nixos.org/guides/how-nix-works.html#nixos

## Hosts

The table below lists the managed hosts and their descriptions:
| Hostname | Device type | Description |
| :-- | :-- | :-- |
| **ceres** | Desktop | Secondary PC at work |
| **eris** | WSL | Primary PC at work |
| **kepler** | VPS | Matrix homeserver <br/> Headscale |
| [**luna**](#luna) | Raspberry Pi Compute Module 4 | NAS |
| [**mars**](#mars) | Raspberry Pi Zero 2 W | - |
| **phobos** | Raspberry Pi 4B | Klipper <br/> Moonraker <br/> Mainsail |
| **terra** | Desktop | Primary PC at home |
| **venus** | Lenovo ThinkPad X230 Tablet | Laptop |

> [!WARNING]
> These configurations have encrypted secrets managed by [sops-nix], and
> cannot be built and successfully activated on machines that do not have a
> `/var/lib/sops-nix/keys.txt` file containing the [age] private key that
> corresponds to an age public key in the root [.sops.yaml](./.sops.yaml) file.
> The age private key is used for decrypting secrets encrypted with the public
> key on NixOS system activation. See [sops-nix].

[age]: https://age-encryption.org/v1
[sops-nix]: https://github.com/Mic92/sops-nix

## Installation Guides

This section contains installation guides to serve as a reminder for myself,
because I can and will forget eventually, how to reflash and/or reinstall
certain hosts. Some hosts can be pre-installed via generated images. I wrote a
small tool (dirty bash script), creatively and aptly named [mountImage], to
mount an image as a loop device to insert/remove files such as private keys
for decrypting secrets, otherwise these images cannot be booted and logged into
or work correctly.

[mountImage]: ./packages/scripts/mountImage.sh

<details>
<summary>luna</summary>

### luna

The host [luna](./hosts/luna/default.nix) is a Raspberry Pi Compute Module 4 (CM4)
mounted to an [Axzez Interceptor] carrier board, serving mostly as a NAS. It
can be installed on a CM4 starting with generating the SD image:
```sh
nix build github:Electrostasy/dots#lunaImage
```

Flash the SD image to eMMC storage using the Raspberry Pi Compute Module 4 IO
Board by bridging the first set of pins on the 'J2' jumper to disable eMMC boot.
With a micro USB cable attached to a host PC, and powering the IO board
with the jumper set, you can run `rpiboot` as root on the host see eMMC storage as a
block device. You can then flash the image in
`./result/sd-image/luna-sd-image-...-aarch64-linux.img` to it, disconnect the
micro USB cable from the host PC, power off the IO Board, detach the CM4 and
attach it to your carrier board. For more info, read this [guide].

[Axzez Interceptor]: https://www.axzez.com/product-page/interceptor-carrier-board
[guide]: https://www.jeffgeerling.com/blog/2020/how-flash-raspberry-pi-os-compute-module-4-emmc-usbboot
</details>

<details>
<summary>mars</summary>

### mars

The host [mars](./hosts/mars/default.nix) is a Raspberry Pi Zero 2 W, currently
unused. It can be installed on a Raspberry Pi Zero 2 W starting with generating the
SD image:
```sh
nix build github:Electrostasy/dots#marsImage
```

Flash the SD image to a selected SD card (up to 32 GB in size) with the SD
image in `./result/sd-image/mars-sd-image-...-aarch64-linux.img` and you can
boot straight away.
</details>

<details>
<summary>phobos</summary>

### phobos

The host [phobos](./hosts/phobos/default.nix) can be installed on a Raspberry Pi 4B
by following the [Tow-Boot](https://tow-boot.org/) firmware Shared Storage strategy,
first flashing it to an SD card, then continuing the installation on the Pi.

#### SD Preparation
Download [Tow-Boot](https://github.com/Tow-Boot/Tow-Boot/releases) latest release
for Raspberry Pi and flash it to an SD card:
```bash
wget https://github.com/Tow-Boot/Tow-Boot/releases/download/release-2021.10-005/raspberryPi-aarch64-2021.10-005.tar.xz
tar xf raspberryPi-aarch64-2021.10-005.tar.xz
sudo dd if=raspberryPi-aarch64-2021.10-005/shared.disk-image.img of=/dev/sda bs=1M oflag=direct,sync status=progress
sudo sgdisk -g /dev/sda
```

#### NixOS Image Preparation
Download an `sd_image` built from [Hydra](https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux):
```bash
wget https://hydra.nixos.org/build/224097540/download/1/nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img.zst
unzstd nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img.zst
```

If you don't have a screen and keyboard to connect to the Pi, add your SSH public
key to the image (and optionally any secrets, for e.g. `age` private key):
```bash
fdisk -l nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img
# Disk nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img: 2.55 GiB, 2736295936 bytes, 5344328 sectors
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# Disklabel type: dos
# Disk identifier: 0x2178694e
#
# Device                                                       Boot Start     End Sectors  Size Id Type
# nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img1      16384   77823   61440   30M  b W95 FAT32
# nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img2 *    77824 5344327 5266504  2.5G 83 Linux

# We need root access for these commands.
sudo -i

mkdir raw
mount -o loop,offset=$((512*77824)) nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img raw

mkdir -p raw/{home/nixos/.ssh,var/lib/sops-nix}
cat ~/.ssh/id_ed25519.pub > raw/home/nixos/.ssh/authorized_keys
cat /var/lib/sops-nix/keys.txt > raw/var/lib/sops-nix/keys.txt

umount raw
rmdir raw
```

Write NixOS image to a USB flash drive:
```bash
dd if=nixos-sd-image-23.11pre494015.0eeebd64de8-aarch64-linux.img of=/dev/sdb bs=1M status=progress
```

#### Installing NixOS
Boot the Pi from the USB with no SD card inserted, after the shell is reached
(can be up to 1 minute) insert the SD card and **continue** (don't destroy the
current partition table made with the Tow-Boot shared storage strategy):
```bash
sudo -i
parted /dev/mmcblk1 -- mkpart ESP fat32 32MiB 546MiB
parted /dev/mmcblk1 -- set 2 esp on
parted /dev/mmcblk1 -- mkpart primary 546MiB 100%

mkfs.vfat -F 32 -n boot /dev/mmcblk1p2
mkfs.btrfs -L nixos /dev/mmcblk1p3
mount -t btrfs -o noatime,compress-force=zstd:3 /dev/mmcblk1p3 /mnt
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/state
umount /mnt

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,state}
mount /dev/mmcblk1p2 /mnt/boot
mount -t btrfs -o subvol=nix,noatime,compress-force=zstd:3 /dev/mmcblk1p3 /mnt/nix
mount -t btrfs -o subvol=state,noatime,compress-force=zstd:3 /dev/mmcblk1p3 /mnt/state
mkdir -p /mnt/{state/,}/var/lib/sops-nix
# Persist secrets key file.
cp /var/lib/sops-nix/keys.txt /mnt/state/var/lib/sops-nix
# Use it for activation during the initial installation.
cp /var/lib/sops-nix/keys.txt /mnt/var/lib/sops-nix

nixos-install --flake github:Electrostasy/dots#phobos --no-root-passwd
nixos-enter --root /mnt
mkdir -p /state/etc/nixos
cd /state/etc/nixos
git clone github:Electrostasy/dots .
exit
reboot
```

</details>
