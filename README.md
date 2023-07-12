# dots
This repository contains declarative [Nix] packages, modules, [NixOS] 
system/user configurations and state management across my various devices. The 
Nix experimental feature [Flakes] is required.

[Nix]: https://nixos.org/guides/how-nix-works.html
[NixOS]: https://nixos.org/guides/how-nix-works.html#nixos
[Flakes]: https://nixos.wiki/wiki/Flakes

## Hosts
This section describes the devices that are managed as NixOS hosts in this 
repository. Their configuration is mostly split across reusable and 
self-contained modules to encourage code reuse and manage complexity. Options 
unique to a specific host, such as configuration that is used solely on that 
host (bootloader settings, state management, etc.), is stored in the 
`configuration.nix` file for each host in the [hosts](./hosts) directory.

The table below lists the managed hosts and their functions:
| Hostname | Device type | Description
| :-- | :-- | :-- |
| **terra** | Desktop | Home PC |
| **phobos** | Raspberry Pi 4B | Klipper <br/> Moonraker <br/> Mainsail |
| **venus** | Lenovo ThinkPad X220 Tablet | Laptop |
| **eris** | WSL | Primary PC at work |
| **ceres** | Desktop | Secondary PC at work |
| **kepler** | VPS | Matrix homeserver <br/> Wireguard VPN |

**Cautionary notes**:
- As these NixOS configurations are specific to my requirements and use cases, 
  they may not be suitable to switch to without at least modifying the 
  hardware-related configuration contained in the host directory's 
  `configuration.nix` file to account for hardware/disk partitioning 
  differences.
- These configurations cannot be built and successfully activated on machines 
  that do not have a `/var/lib/sops-nix/keys.txt` file containing the [age] 
  private key that corresponds to an age public key in the root 
  [.sops.yaml](./.sops.yaml) file. The age private key is used for decrypting 
  user account passwords and other secrets encrypted with the public key. You 
  can read more about secrets management in the [sops-nix] project page.

[age]: https://age-encryption.org/v1
[sops-nix]: https://github.com/Mic92/sops-nix

---
If nothing else, I hope this will be at least as useful to others as reading 
other peoples' public NixOS configurations was for me.
