{ pkgs, lib }:

let
  inherit (pkgs) callPackage;
in

rec {
  eww-wayland = callPackage ./eww-wayland { };
  firefox-custom = callPackage ./firefox { };
  gamescope = callPackage ./gamescope { };
  nerdfonts-patch = callPackage ./nerdfonts-patch { };
  simp1e-cursor-theme = callPackage ./simp1e-cursor-theme { };
  umc = callPackage ./umc { };
  wlopm = callPackage ./wlopm { };
  wlr-spanbg = callPackage ./wlr-spanbg { };

  wayfire-git = callPackage ./wayfire { };
  wayfirePlugins = lib.makeScope pkgs.newScope (self: with self; {
    dbus-interface = callPackage ./wayfire/wayfirePlugins/wayfire-dbus { wayfire = wayfire-git; };
    firedecor = callPackage ./wayfire/wayfirePlugins/firedecor { wayfire = wayfire-git; };
    plugins-extra = callPackage ./wayfire/wayfirePlugins/wayfire-plugins-extra { wayfire = wayfire-git; };
    shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { wayfire = wayfire-git; };
  });

  vimPlugins = lib.makeScope pkgs.newScope (self: with self; {
    heirline-nvim = pkgs.vimUtils.buildVimPlugin {
      pname = "heirline-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "rebelot";
        repo = "heirline.nvim";
        rev = "7b4aabc2c55d50fbd4a4923e847079d6fa9a8613";
        sha256 = "sha256-xopPEx5Ig10iBTy6QEzFLxyFwbNXdzAGYS5y6injW8o=";
      };
      version = "unstable-2022-05-25";
    };
    hlargs-nvim = pkgs.vimUtils.buildVimPlugin {
      pname = "hlargs-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "m-demare";
        repo = "hlargs.nvim";
        rev = "e3218d790edaa138fcc27f91ddb6a7e9604f27ae";
        sha256 = "sha256-qhOM/tm/G4WkJd6KtraFmV4z9aLrwSdYb2S80ystBOs=";
      };
      version = "unstable-2022-05-14";
    };
  });
}
