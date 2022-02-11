# This module allows non-native aarch64-linux package compilation and
# derivation building for aarch64-linux architectures. With this module enabled
# you can build and activate a configuration remotely between architectures:

# sudo nixos-rebuild switch --target-host pi@phobos --flake .#phobos --use-remote-sudo --use-subtitutes

# This will however build everything on your host system through QEMU (very slow!).
# Currently doesn't fetch binaries from the binary cache. No idea how to
# make it work.

{ config, ... }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
