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
| **luna** | Raspberry Pi Compute Module 4 | NAS |
| **mars** | Raspberry Pi Zero 2 W | - |
| **phobos** | Raspberry Pi 4 Model B | Klipper <br/> Moonraker <br/> Mainsail |
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
can be installed on a CM4 by first generating the SD image:
```sh
nix build github:Electrostasy/dots#lunaImage
```

Flash the SD image to eMMC storage using the Raspberry Pi Compute Module 4 IO
Board by bridging the first set of pins on the 'J2' jumper to disable eMMC boot.
With a micro USB cable attached to a host PC, and powering the IO Board
with the jumper set, you can run `rpiboot` as root on the host to see eMMC
storage as a block device. You can then flash the image in
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
unused. It can be installed on a Raspberry Pi Zero 2 W by first generating the
SD image:
```sh
nix build github:Electrostasy/dots#marsImage
```

Flash the SD image to a selected microSD card (up to 32 GB in size) with the SD
image in `./result/sd-image/mars-sd-image-...-aarch64-linux.img` and you can
boot straight away.
</details>

<details>
<summary>phobos</summary>

### phobos

The host [phobos](./hosts/phobos/default.nix) is a Raspberry Pi 4 Model B, used
for controlling the Original Prusa MK3S+ 3D printer flashed with Klipper firmware.
It serves a Mainsail web interface for remote monitoring and management of the
3D printer, and has a Raspberry Pi Camera Module 3 Wide connected over CSI interface.
It can be installed on a Raspberry Pi 4 Model B by first generating the SD image:
```sh
nix build github:Electrostasy/dots#phobosImage
```

Flash the SD image in `./result/sd-image/phobos-sd-image-...-aarch64-linux.img`
to a selected microSD card and you can boot straight away.
</details>
