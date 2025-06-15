# Hybrid MBR on Raspberry Pi

## What is this?

This document details the results of some research and experiments I have done
on a Raspberry Pi Zero 2W in trying to get it booting with U-Boot and
systemd-boot on a GPT microSD card. Resources online were conflicting, so here
is yet another attempt to figure this out.


## In short

In order to boot Raspberry Pi boards older than the 4B, the first FAT partition
in the MBR partition table has to have MBR partition type code `0c` and contain
the necessary Raspberry Pi firmware files.

We can achieve this by converting our Protective MBR in the GPT to a [hybrid
MBR] and then changing the MBR partition [type code]:
```sh
sgdisk --hybrid=1:EE $image
sfdisk --label-nested dos --part-type $image 1 0c
```

[hybrid MBR]: https://www.rodsbooks.com/gdisk/hybrid.html
[type code]: https://aeb.win.tue.nl/partitions/partition_types-1.html


## At length

The gptfdisk project uses internal 16-bit extensions of the original MBR 8-bit
type codes. For the purposes of this text, I will be referring to them as
internal MBR partition type codes in areas.

In order to get the MBR partition type code `0c` for the first FAT partition in
our Protective MBR, it is reasonable to assume that it should first be of GPT
partition type "Microsoft basic data" before hybridizing, because it is mapped
to the internal MBR partition type code `0x0c00`. After hybridizing, we should
get the expected MBR partition type code `0c` for it, however, it will always
be of type code `07` instead, even though the FAT-32 LBA internal type code
(provided below) is `0x0c00`. In the [gptfdisk source code], the internal MBR
partition type codes are mapped to GPT GUIDs, in particular the GPT partition
GUID for "Microsoft basic data" is re-used to map across many different
internal MBR partition type codes and hybridizing any of these with gptfdisk
tools will always yield `07` in the hybrid MBR.

See this fragment from the [gptfdisk source code]:
```cpp
// DOS/Windows partition types, most of which are hidden from the "L" listing
// (they're available mainly for MBR-to-GPT conversions).
AddType(0x0100, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // FAT-12
AddType(0x0400, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // FAT-16 < 32M
AddType(0x0600, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // FAT-16
AddType(0x0700, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 1); // NTFS (or HPFS)
AddType(0x0701, "558D43C5-A1AC-43C0-AAC8-D1472B2923D1", "Microsoft Storage Replica", 1);
AddType(0x0702, "90B6FF38-B98F-4358-A21F-48F35B4A8AD3", "ArcaOS Type 1", 1);
AddType(0x0b00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // FAT-32
AddType(0x0c00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // FAT-32 LBA
AddType(0x0c01, "E3C9E316-0B5C-4DB8-817D-F92DF00215AE", "Microsoft reserved");
AddType(0x0e00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // FAT-16 LBA
AddType(0x1100, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden FAT-12
AddType(0x1400, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden FAT-16 < 32M
AddType(0x1600, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden FAT-16
AddType(0x1700, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden NTFS (or HPFS)
AddType(0x1b00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden FAT-32
AddType(0x1c00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden FAT-32 LBA
AddType(0x1e00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", 0); // Hidden FAT-16 LBA
AddType(0x2700, "DE94BBA4-06D1-4D40-A16A-BFD50179D6AC", "Windows RE");
```

In the above code fragment, ideally we would get `0c` from "Microsoft basic
data", which is mapped to `0x0c00`, when hybridizing the Protective MBR with it
in it, but for the reasons mentioned above, this does not happen.

If we want to use U-Boot's emulated EFI environment and boot using
systemd-boot, then our first partition has to be the ESP with the firmware in
it. If the first FAT partition contains our ESP and it is not of type "EFI
system partition", then systemd-gpt-auto-generator will not be able to mount it
to /boot, which is why we cannot use "Microsoft basic data" for ESP unless we
populate the /etc/fstab with how to mount /boot. According to this [forum
post], the first FAT partition containing the Raspberry Pi firmware can be
either of type "Microsoft basic data" or "EFI system partition". The Raspberry
Pi on-chip ROM can therefore find the firmware files on the ESP and we can dump
all the firmware there, manually change the first FAT partition code to `0c` in
the hybrid MBR, and it will boot successfully. The bootable flag is also
ignored by the on-chip ROM, so setting it in the MBR has no effect.

However, if the firmware is separated from the ESP into different partitions -
"Microsoft basic data" followed by "EFI system partition" - then the Raspberry
Pi will not boot at all, not even a flashing LED. Playing around with different
partition type codes, partition order and which partitions are added to the
hybrid MBR makes no difference. The same applies if we disregard the [forum
post] and use "Microsoft reserved" for the firmware partition which has the
internal MBR type code of `0x0c01` and after hybridizing becomes `0c` in the
MBR - we still cannot boot.

Taking into account **all** of the above, the firmware **has** to be present in
the ESP, and for it to be found by the Raspberry Pi on-chip ROM, the
requirements are as follows:
1. The GPT's Protective MBR must be turned into a hybrid MBR.
2. The first FAT partition in the hybrid MBR with the Raspberry Pi firmware has
   to have the MBR partition type code `0c` as expected by the Raspberry Pi on-chip ROM.
3. If we want to use U-Boot's EFI emulation, the first FAT partition in the
   hybrid MBR must also contain our /boot and have the EFI GUID for the ESP.

[gptfdisk source code]: https://sourceforge.net/p/gptfdisk/code/ci/0e13e907ced9981024d0bdec7e2dc1b2081c9cbe/tree/parttypes.cc#l80
[forum post]: https://forums.raspberrypi.com/viewtopic.php?t=319435#p1912314
