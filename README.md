# dots

This repository contains a [Nix] [flake] for packages, [NixOS] modules &
configurations across my various devices. This README can be considered as
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
> The configurations cannot be successfully activated on machines that do not
> have a `/var/lib/sops-nix/keys.txt` file containing the [`age`] private key
> corresponding to an `age` public key in the root [.sops.yaml] file.

The table below lists the managed hosts and their descriptions:

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

[`age`]: https://age-encryption.org/v1
[.sops.yaml]: ./.sops.yaml


## Key Rotation Notes

The `age` private key is used for decrypting secrets encrypted with the public
key on NixOS system activation. If the key is unavailable, you will not be able
to login and certain services will not function correctly. See [sops-nix] for
details.

As mentioned above, the `age` private key is located in
`/var/lib/sops-nix/keys.txt`, and has to be generated before secrets can be
decrypted or rotated. The `age` private key can be generated using the
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

Afterwards, the only things left to do are:
1. update the public key in the `.sops.yaml` configuration file
2. and move the new private key in `~/keys.txt` to `/var/lib/sops-nix/keys.txt`.

The new private key has to be deployed to each host manually.

[sops-nix]: https://github.com/Mic92/sops-nix


# Installation Guides

This section contains installation guides and documentation for certain devices
managed by this flake, in the order of the table provided in the previous
section.

> [!IMPORTANT]
>
> Some of the following hosts can be pre-installed via generated images. In
> order for NixOS activation to be successful, the `age` private key needs to be
> inserted into the image at the expected location of
> `/var/lib/sops-nix/keys.txt`.
>
> A command is available to mount a partition and open a shell at its root in
> order to add, remove or change files:
>
> ```sh
> nix run github:Electrostasy/dots#mountImage -- -i mars-sd-image*.img
> ```


## deimos

The host [deimos] is a Raspberry Pi Zero 2 W, used for controlling the Original
Prusa MK3S+ 3D printer flashed with Klipper firmware. It serves a Mainsail web
interface for remote monitoring and management of the 3D printer.

[deimos]: ./hosts/deimos/default.nix


### Building the image

The NixOS SD image to be flashed can be built using the following command:

```sh
nix build github:Electrostasy/dots#deimosImage
```


### Flashing the image

The NixOS SD image may be flashed to a selected microSD card (up to 32 GB in
size) using the following command:

```sh
dd if=deimos-sd-image*.img of=/dev/sda bs=1M status=progress
```


## luna

The host [luna] is a Raspberry Pi Compute Module 4 (CM4) mounted to an [Axzez
Interceptor] carrier board, serving as Network Attached Storage.

[luna]: ./hosts/luna/default.nix
[Axzez Interceptor]: https://www.axzez.com/product-page/interceptor-carrier-board


### Building the image

The NixOS SD image to be flashed can be built using the following command:

```sh
nix build github:Electrostasy/dots#nixosConfigurations.lunaImage
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
   sudo rpiboot
   ```

5. Flash the image to it:

   ```sh
   sudo dd if=luna-sd-image*.img of=/dev/sda bs=1M conv=fsync status=progress
   ```

6. Disconnect the micro USB cable from the host PC.
7. Power off the IO Board.
8. Detach the CM4 and attach it to your carrier board.

> [!TIP]
>
> For more information on interacting with and flashing a Raspberry Pi Compute
> Module 4, refer to this [guide].

[guide]: https://www.jeffgeerling.com/blog/2020/how-flash-raspberry-pi-os-compute-module-4-emmc-usbboot


## mars

The host [mars] is a [FriendlyElec NanoPC-T6 LTS], currently unused.

The preferred way would be to flash both `u-boot` and the NixOS image to SPI and
eMMC respectively, however, at the time of writing, due to [limitations] in
`rkdeveloptool`, the open-source command line flashing tool developed by
Rockchip as an alternative to the closed-source `upgrade_tool`, we cannot select
between SPI and eMMC flash memory when flashing. Because of this, we build an
installer image with `u-boot` included, and flash on the target system instead
of externally over USB.

> [!TIP]
>
> For more information, see the comprehensive [Collabora guide] on hardware
> enablement for the RK3588 platform, primarily targeted towards the Radxa ROCK
> 5B SBC.

[mars]: ./hosts/mars/default.nix
[FriendlyElec NanoPC-T6 LTS]: https://wiki.friendlyelec.com/wiki/index.php/NanoPC-T6
[limitations]: https://github.com/rockchip-linux/rkdeveloptool/issues/94
[Collabora guide]: https://gitlab.collabora.com/hardware-enablement/rockchip-3588/notes-for-rockchip-3588/-/blob/7338fa2891fbc37129d62b2809b159a33db6b687/upstream_uboot.md#writing-binaries-to-sd-card-for-booting-from-sd-card


### Building the image

The NixOS installer SD image to be flashed can be built using the following
command:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure github:Electrostasy/dots#marsImage
```

> [!TIP]
>
> Since the Rockchip proprietary bootloader blobs (TPL) for RK3588 are unfree,
> which are used to build u-boot, unfree packages need to be allowed. A simple
> way to do that is to export the environment variable `NIXPKGS_ALLOW_UNFREE=1`,
> which is detected in builds only with the `--impure` flag, making the builds
> impure.


### Flashing the image

The NixOS installer SD image may be flashed to a selected microSD card or USB
flash drive using the following command:

```sh
dd if=mars-sd-image*.img of=/dev/sda bs=1M status=progress
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


## phobos

The host [phobos] is a Raspberry Pi 4 Model B, used to host the dendrite Matrix
homeserver and the headscale coordination server for Tailscale VPN to link my
devices together.

[phobos]: ./hosts/phobos/default.nix


### Building the image

The NixOS SD image to be flashed can be built using the following command:

```sh
nix build github:Electrostasy/dots#phobosImage
```


### Flashing the image

Flash the SD image to a selected microSD card using the following command:

```sh
dd if=phobos-sd-image*.img of=/dev/sda bs=1M status=progress
```
