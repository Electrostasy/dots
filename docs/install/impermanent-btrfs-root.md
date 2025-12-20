# Installation guide for impermanent BTRFS root devices

[Mercury], a Asus ROG Flow Z13 (2022) laptop, and [terra], a desktop PC, have
an [erase-your-darlings] inspired encrypted btrfs root setup, where on every
boot the root subvolume is restored from an empty snapshot. The empty snapshot
is set up during installation and restored from on every boot.

1. Create the ESP, LUKS encrypted root and swap partitions:
   ```sh
   sgdisk -n 1::+1G -t 1:ef00 -n 2::-16G -t 2:8309 -n 3::0 -t 3:8200 /dev/nvme0n1
   cryptsetup luksFormat --uuid eea26205-2ae5-4d2c-9a13-32c7d9ae2421 /dev/nvme0n1p2
   cryptsetup luksOpen --perf-no_read_workqueue --perf-no_write_workqueue --allow-discards --persistent /dev/nvme0n1p2 cryptroot
   ```
2. Format the partitions:
   ```sh
   mkfs.vfat -F 32 -n BOOT /dev/nvme0n1p1
   mkfs.btrfs -L nixos /dev/mapper/cryptroot
   mkswap -L swap /dev/nvme0n1p3
   ```
3. Set up the btrfs subvolumes and empty root snapshot:
   ```sh
   mount /dev/mapper/cryptroot -o subvol=/ /mnt
   btrfs subvolume create /mnt/{root,nix,persist,persist/{cache,state}}
   btrfs subvolume set-default /mnt/root
   btrfs subvolume snapshot -r /mnt/{root,root-blank}
   umount /mnt
   ```
4. Prepare the mountpoints for installation:
   ```sh
   mount /dev/mapper/cryptroot -o subvol=root /mnt
   mount /dev/mapper/cryptroot -o subvol=nix -m /mnt/nix
   mount /dev/mapper/cryptroot -o subvol=persist -m /mnt/persist
   btrfs property set /mnt/nix compression zstd:1
   btrfs property set /mnt/persist compression zstd:1
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
[Mercury]: ./hosts/mercury/default.nix
[terra]: ./hosts/terra/default.nix
