# dots

This repository stores my NixOS configurations. [Read about Nix and
NixOS](https://nixos.org/learn/).


## Installation guides

Installation guides are provided for many NixOS configurations managed by this
repository:
- [Impermanent BTRFS root](./docs/install/impermanent-btrfs-root.md) devices
- [Raspberry Pi](./docs/install/raspberry-pi.md) devices
- [Rockchip](./docs/install/rockchip.md) devices

Please do not try to build and activate these NixOS configurations yourselves
unless you have the appropriate hardware and [`age` private
key](./docs/maintenance/secret-rotation.md) present in
`/var/lib/sops-nix/keys.txt`.


# License

This project is licensed under the [MIT License](LICENSE), unless specified
otherwise.
