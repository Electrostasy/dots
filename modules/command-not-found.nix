{ config, pkgs, lib, ... }:

let
  cfg = config.programs.command-not-found;
in

{
  # TODO: If https://github.com/NixOS/nixpkgs/pull/415070 is merged, remove
  # these and set our command-not-found as programs.command-not-found.package.
  disabledModules = [ "programs/command-not-found/command-not-found.nix" ];

  options.programs.command-not-found = {
    enable = lib.mkEnableOption ''
      interactive shells showing which Nix package (if any) provides a missing
      command.

      Requires either nix-channels to be set and downloaded (sudo nix-channels
      --update) or the nixpkgs flake input set to a lockable tarball
      (https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz)'' // { default = true; };

    package = lib.mkPackageOption pkgs "command-not-found" { };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      visible = false;
      readOnly = true;
      description = "Resulting customized command-not-found package.";
    };

    dbPath = lib.mkOption {
      default = "${pkgs.path}/programs.sqlite";
      description = ''
        Absolute path to programs.sqlite.

        By default this file will be provided by your channel or nixpkgs tarball (nixexprs.tar.xz).
      '';
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.command-not-found.finalPackage = cfg.package.override {
      inherit (cfg) dbPath;
    };

    programs.bash.interactiveShellInit = ''
      command_not_found_handle() {
        "${lib.getExe cfg.finalPackage}" "$@"
      }
    '';

    programs.zsh.interactiveShellInit = ''
      command_not_found_handler() {
        "${lib.getExe cfg.finalPackage}" "$@"
      }
    '';

    # NOTE: Fish itself checks for command-not-found, set it explicitly.
    programs.fish.interactiveShellInit = ''
      function fish_command_not_found
        "${lib.getExe cfg.finalPackage}" $argv
      end
    '';

    environment.systemPackages = [ cfg.finalPackage ];
  };
}
