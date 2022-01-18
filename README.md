# NixOS Configuration
This repository stores the Nix flake-based NixOS configuration for my desktop
workstation and my small fleet of Raspberry Pi devices. While I've tried to
make it somewhat generic w.r.t. hardware, it is not recommended to blindly
copy without modifications.

#### Notable features:
- Wayfire Wayland compositor using a custom work-in-progress Home-Manager
  [module](./nixos/home-manager/wayfire/default.nix)
- [btrfs/tmpfs root](./hosts/phobos)
- [Steam](./nixos/steam) through a systemd-nspawn container
- Neovim Lua configuration with plugins
  [managed using Home-Manager](./modules/neovim/default.nix)
