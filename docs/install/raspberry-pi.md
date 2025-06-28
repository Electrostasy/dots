# Installation guides for Raspberry Pi devices

This document contains installation guides for the following Raspberry Pi
devices:
- [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)
- [Raspberry Pi Compute Module 4](https://www.raspberrypi.com/products/compute-module-4/?variant=raspberry-pi-cm4001000)
- [Raspberry Pi Zero 2 W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)


## Raspberry Pi 4 Model B
### phobos

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


## Raspberry Pi Compute Module 4
### luna

Luna is a mounted on an [Axzez Interceptor v1.0] carrier board, which does not
support disabling eMMC boot for flashing. It must first be mounted to a
[Raspberry Pi Compute Module 4 IO Board] in order to flash the eMMC.

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

[Axzez Interceptor v1.0]: https://www.axzez.com/product-page/interceptor-carrier-board
[Raspberry Pi Compute Module 4 IO Board]: https://www.raspberrypi.com/products/compute-module-4-io-board/


## Raspberry Pi Zero 2 W
### deimos

Build the image on an `aarch64-linux` platform and insert the `age` private
key:
```sh
nixos-rebuild build-image --flake github:Electrostasy/dots#deimos --image-variant raw
cp ./result/nixos-deimos* .
systemd-dissect --with nixos-deimos* install -D {,.}/var/lib/sops-nix/keys.txt
```

Due to the limitations of the Raspberry Pi Zero 2 W, booting from GPT formatted
media directly is not supported and the image needs a [hybrid MBR] containing
the partition with Raspberry Pi firmware:
```sh
echo -e 'size=+1GiB, type=0c\n start=1, type=ee' | sfdisk -Y dos nixos-deimos*
```

Flash the image to microSD card:
```sh
dd if=nixos-deimos* of=/dev/sdX bs=1M status=progress oflag=direct
```

[hybrid MBR]: ../raspberry-pi/hybrid-mbr.md
