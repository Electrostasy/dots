{ config, pkgs, ... }:

{
  # Register the contents of the Nix store in the Nix database, based on the
  # work in https://github.com/NixOS/nixpkgs/pull/351699.
  image.repart.partitions."20-root".contents."/nix/var/nix".source = pkgs.runCommand "nix-state" { nativeBuildInputs = [ pkgs.buildPackages.nix ]; } ''
    mkdir -p $out/profiles
    ln -s ${config.system.build.toplevel} $out/profiles/system-1-link
    ln -s /nix/var/nix/profiles/system-1-link $out/profiles/system

    export NIX_STATE_DIR=$out
    nix-store --load-db < ${pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; }}/registration
  '';
}
