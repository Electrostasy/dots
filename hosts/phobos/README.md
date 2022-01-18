# Bootstrapping
## Preparing the Hydra image for headless install over SSH

Download the latest [Hydra built images](https://hydra.nixos.org/build/164013075)
from CI, and then copy over your SSH public key for headless login and flash it
to an SD card. The default pre-built images have OpenSSH enabled out of the box,
but login is not configured.

Steps to accomplish this:
```bash
unzstd nixos-sd-image-21.11.335143.9acedfd7ef3-aarch64-linux.img.zst
# Sector size * Start sector = Mount offset
# 512         * 77824        = 39845888 
fdisk -l nixos-sd-image-21.11.335143.9acedfd7ef3-aarch64-linux.img

mkdir raw
sudo mount -o loop,offset=39845888 nixos-sd-image-21.11.335143.9acedfd7ef3-aarch64-linux.img raw
mkdir -p raw/home/nixos/.ssh/authorized_keys
cat ~/.ssh/id_rsa.pub >> raw/home/nixos/.ssh/authorized_keys
sudo umount raw
rm -r raw

sudo dd if=nixos-sd-image-21.11.335143.9acedfd7ef3-aarch64-linux.img of=/dev/sdg bs=1M status=progress
```

The Pi should boot without any issues, and you can SSH into it using `ssh nixos@$IP`.
Now setup the partitions, filesystems and configuration - I use a
[btrfs](https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html)+
[tmpfs](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/) root
configuration (inspired by [this](https://grahamc.com/blog/erase-your-darlings)),
where my stateful directories are stored on the SSD, and everything else is on tmpfs.

It is assumed that every command is run as root: `sudo -i`.

Create partitions for `/boot`, swap and data:
```bash
wipefs -af /dev/sda
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary linux-swap 512MiB 16GiB
parted /dev/sda -- mkpart primary 16GiB 100%
```

Create filesystems:
```bash
mkfs.vfat -F 32 -n boot /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mkfs.btrfs -L nixos /dev/sda3
```

Setup btrfs subvolumes:
```bash
mount -t btrfs -o noatime,nodiratime,compress=zstd,ssd /dev/sda3 /mnt
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/state
mkdir -p /mnt/state/{etc/nixos,var/log}
umount /mnt
```

Setup root filesystem on tmpfs:
```bash
mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,state,etc/nixos,var/log}
mount /dev/sda1 /mnt/boot
mount -t btrfs -o subvol=nix,noatime,nodiratime,compress=zstd,ssd /dev/sda3 /mnt/nix
mount -t btrfs -o subvol=state,noatime,nodiratime,compress=zstd,ssd /dev/sda3 /mnt/state
mount -o bind /mnt/state/etc/nixos /mnt/etc/nixos
mount -o bind /mnt/state/var/log /mnt/var/log
```

Now you can either build a configuration from the flake, or make your own.
For historical reasons, this was my process to bootstrap a working configuration
from scratch.

Generate an initial configuration:
```bash
nixos-generate-config --root /mnt
```

`nixos-generate-config` won't detect your configuration perfectly accurately,
there are some adjustments to be made to `hardware-configuration.nix` first:
```nix
{
  fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];
}
```
In my case, the btrfs mount options (and SSD) were not detected either, and I
had to add them manually:
```nix
{
  fileSystems."/nix".options = [ "subvol=nix" "noatime" "nodiratime" "compress=zstd" "ssd" ];
  fileSystems."/state".options = [ "subvol=state" "noatime" "nodiratime" "compress=zstd" "ssd" ];
}
```
Additionally, the bind mount paths were detected erroneously, and I had to change
them from `device = "/state/state/etc/nixos";` to `device = "/state/etc/nixos";`
for both `/etc/nixos` and `/var/log` bind mounts.

You may also need to add `neededForBoot = true;` to the `/var/log` and `/state`
mounts, in my case the Pi would not be able to mount `/var/log` without this,
and would just be stuck in the stage 1 load.

Optionally, I use `depends = [ "/state" ];` for the `/var/log` bind mount as well,
to ensure its dependency is mounted first, but it's probably unnecessary.

In the `configuration.nix`, I recommend setting these:
```nix
{
  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.kernelParams = [
    "8250.nr_uarts=1"
    "console=ttyAMA0,115200"
    "console=tty1"
    "cma=128M"
  ];
  boot.loader.raspberryPi = {
    enable = true;
    version = 4;
  };
  users.mutableUsers = false;
}
```
You will need to set up your users with initialHashedPassword as well.

After setting these options, run:
```bash
nixos-install --no-root-passwd
```

Before rebooting, I would [update my firmware](https://nix.dev/tutorials/installing-nixos-on-a-raspberry-pi#updating-firmware)
and set `program_USB_boot_mode=1` in `config.txt` in the `/boot` partition
to enable booting from USB (you can do this after rebooting too, if it doesn't boot again).
Ensure that the `/boot` partition actually contains the firmware needed to boot!

Execute `shutdown now` - take out the SD card, boot again from SSD, it should work.

See the [hardware-configuration.nix](./hardware-configuration.nix) for more details.
