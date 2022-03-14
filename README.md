# dots
You have stumbled upon my dotfiles repository. There are no dotfiles to be
found here, only declarative infrastructure-as-code written in
[Nix](https://nixos.org/explore.html) to reproducibly synchronise system/user
configuration across my various devices.

## General requirements
NixOS systems I use loosely follow these requirements:
* Ephemeral root
* Wayland compositing servers instead of X servers
* PipeWire instead of PulseAudio
* Declarative instead of imperative configuration
* Self-host all the things

## NixOS configuration
The configuration is split across reusable and self-contained modules which
should be relatively safe to copy, if not without minor alterations.

Brief outline of my NixOS configurations and the devices I use them on:
| Hostname | Device type | Description
| :-- | :-- | :-- |
| **mars** | Desktop PC | Primary workstation |
| **phobos** | Raspberry Pi 4B | Matrix homeserver & local nfs fileserver |
| **deimos** | Raspberry Pi 3B+ |  _Currently unused_ |
| **mercury** | Lenovo ThinkPad T420 | Laptop/mobile workstation |


I have chosen to use the planets of our solar system as host names:
[**phobos**](hosts/phobos) and [**deimos**](hosts/deimos) are both moons of
[**mars**](hosts/mars), as they sit in (mostly) one place, while
[**mercury**](hosts/mercury) I generally take with me.

These NixOS configurations are specific to my requirements and use cases,
therefore they may not be suitable to switch to by others without at least
modifying the `hardware-configuration.nix` file in the host directory to
account for hardware/disk partitioning differences and/or the persistent state
directories.

If nothing else, I hope this will be at least as useful to others as reading
other peoples' public NixOS configurations was for me.
