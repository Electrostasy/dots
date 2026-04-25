# Some systems, such as Raspberry Pi SBCs (specifically the Zero 2 W and Model
# 3 B+), do not support booting from GPT partitioned boot media, they only
# support booting from MBR partitioned boot media. MBR is not supported by
# neither systemd-repart, systemd-boot or systemd-gpt-auto-generator. A hybrid
# MBR is needed for compatibility with these SBCs, which this profile provides.

# These are the constraints we have to work with:
# 1. The Raspberry Pi firmware _must_ be on the first FAT partition, anything
#    else will _not_ POST or boot.
# 2. On-chip ROM expects the first FAT MBR partition type code to be 0c or the
#    Raspberry Pi firmware will _not_ be located.
# 3. The first FAT partition must be of GPT partition type "EFI system partition"

# The solution is to use the interactive `gdisk` by piping a series of commands
# to its stdin to create the hybrid MBR and specifically choose the correct 0c
# MBR partition type code for the first partition:
# $ echo -e 'r\nh\n1\nn\n0c\nn\nn\nw\ny\n' | gdisk $image

# The usual go-to option for creating a Hybrid MBR, `sgdisk --hybrid`, does not
# satisfy constraints 2 and 3. GPT partition type "Microsoft Basic Data" can be
# used for Raspberry Pi [1], but when creating a Hybrid MBR with `sgdisk`,
# while the GPT partition type "Microsoft Basic Data" can in theory be mapped
# to MBR partition type code 0c, in practice, it does not, due to the GPT
# partition "Microsoft Basic Data" GUID being re-used to map across many
# different internal 16-bit extensions of the original MBR 8-bit type codes -
# because of this, hybridizing them with `sgdisk` automatically picking the MBR
# partition type code will usually yield something other than 0c, see [2] for
# more details (specifically FAT-32 LBA). Using GPT partition type "Microsoft
# Basic Data" instead of "EFI system partition" also makes the image
# incompatible with systemd-boot and systemd-gpt-auto-generator.

# Another solution is changing the MBR partition type code after creating the
# hybrid MBR:
# $ sgdisk --hybrid=1:EE $image
# $ sfdisk --label-nested dos --part-type $image 1 0c
# The hybrid MBR can also be created with only `sfdisk`, but this requires more
# work to get the partition size:
# $ echo -e 'size=+1GiB, type=0c\n start=1, type=ee' | sfdisk --label-nested dos $image

# [1]: https://forums.raspberrypi.com/viewtopic.php?t=319435#p1912314
# [2]: https://sourceforge.net/p/gptfdisk/code/ci/0e13e907ced9981024d0bdec7e2dc1b2081c9cbe/tree/parttypes.cc#l80

{ config, pkgs, lib, ... }:

{
  assertions = [
    {
      assertion = (lib.head (lib.attrsToList config.image.repart.partitions)).value.repartConfig.Type == "esp";
      message = "hybrid-mbr image profile requires the ESP to be the first partition";
    }
  ];

  system.build.image = lib.mkOverride 99 (config.image.repart.image.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ pkgs.gptfdisk ];

    postBuild = ''
      echo 'Creating a hybrid MBR for the image'
      echo -e 'r\nh\n1\nn\n0c\nn\nn\nw\ny\n' | gdisk '${config.image.baseName}.${config.image.extension}' > /dev/null
      if [ $? -ne 0 ]; then
        echo 'gdisk returned non-zero exit status!'
      fi
    '';
  }));
}
