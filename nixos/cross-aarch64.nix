{ config, ... }:

# Include this module for any systems that may cross-compile ISO images
# to aarch64

{
  # Allow this system to crosscompile packages for aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix = {
    binaryCaches = [ "https://arm.cachix.org/" ];
    binaryCachePublicKeys = [ "arm.cachix.org-1:5BZ2kjoL1q6nWhlnrbAl+G7ThY7+HaBRD9PZzqZkbnM=" ];
  };
}
