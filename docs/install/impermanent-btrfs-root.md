# Installation guide for impermanent BTRFS root devices

This guide describes the steps necessary to install a btrfs encrypted root
NixOS system with rollbacks of the root file tree to an empty snapshot on every
boot, inspired by [erase-your-darlings]. Points of consideration:
- System architecture is assumed to be x86_64, for other architectures, the
  appropriate root partition typecode must be used for compatibility with
  `root=gpt-auto` setups, see `sgdisk -L`.
- Subvolumes are assumed to follow the flat layout, where the root file tree is
  contained in `/root`, and the empty root snapshot in `/root-blank`.
- The rollbacks are accomplished using a [systemd service] in the initrd,
  therefore systemd must be enabled in the initrd:
  ```nix
  {
    boot.initrd.systemd.enable = true;
  }
  ```
- The btrfs subvolume that is marked default is the one that is rolled back.

The installation steps are as follows:
1. Partition the installation device:
   ```sh
   # `8304` corresponds to `Linux x86-64 root (/)`, see `sgdisk -L`.
   sgdisk -n 1::+1G -t 1:ef00 -n 2::-16G -t 2:8304 -n 3::0 -t 3:8200 /dev/nvme0n1
   ```
2. Format the partitions:
   ```sh
   mkfs.vfat -F 32 /dev/nvme0n1p1
   cryptsetup luksFormat /dev/nvme0n1p2
   cryptsetup luksOpen --perf-no_read_workqueue --perf-no_write_workqueue --allow-discards --persistent /dev/nvme0n1p2 root
   mkfs.btrfs /dev/mapper/root
   mkswap /dev/nvme0n1p3
   ```
3. Set up the btrfs subvolumes and empty root snapshot:
   ```sh
   mount /dev/mapper/root -o subvol=/ /mnt
   btrfs subvolume create /mnt/{root,nix,persist,persist/{cache,state}}
   btrfs subvolume set-default /mnt/root
   btrfs subvolume snapshot -r /mnt/{root,root-blank}
   umount /mnt
   ```
4. Prepare the mountpoints for installation:
   ```sh
   mount /dev/mapper/root /mnt
   mount /dev/mapper/root -o subvol=nix -m /mnt/nix
   mount /dev/mapper/root -o subvol=persist -m /mnt/persist
   mount /dev/nvme0n1p1 -m /mnt/boot
   btrfs property set /mnt/nix compression zstd:1
   btrfs property set /mnt/persist compression zstd:1
   ```
5. If using sops-nix, install the private key:
   ```sh
   install -D keys.txt /mnt/persist/state/var/lib/sops-nix/keys.txt
   ```
6. Download, build and install the NixOS configuration:
   ```sh
   git clone https://github.com/Electrostasy/dots /mnt/persist/state/etc/nixos
   nixos-install --flake /mnt/persist/state/etc/nixos#terra --no-root-passwd
   ```
7. Reboot into the system:
   ```sh
   reboot
   ```

[erase-your-darlings]: https://grahamc.com/blog/erase-your-darlings/
[systemd service]: ../../modules/restore-root.nix
