{ pkgs, lib }:

let
  inherit (pkgs) callPackage;
in

rec {
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

  iosevka-nerdfonts = nerdfonts-patch (pkgs.iosevka.override {
    privateBuildPlan = {
      family = "Iosevka Custom";
      spacing = "normal";
      serifs = "sans";
      no-cv-ss = true;
      no-litigation = true;
    };
    set = "custom";
  });
  opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

  vimPlugins = lib.makeScope pkgs.newScope (self: with self; {
    heirline-nvim = pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "heirline-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "rebelot";
        repo = "heirline.nvim";
        rev = "805a158b2b44b015f7966b03cd9def489984be8f";
        sha256 = "sha256-++52rJvzOjglHzMUp7L1+1+MbcniMGq8RwUSl7TCY9s=";
      };
      version = "unstable-2022-07-06";
    };
    hlargs-nvim = pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "hlargs-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "m-demare";
        repo = "hlargs.nvim";
        rev = "fe513dabb5c6bae5831dd1d4941e480415521503";
        sha256 = "sha256-6/TkM4olziwGPaiXPNYdjKwwHISM5jrHJdufzE830Ug=";
      };
      version = "unstable-2022-07-08";
    };
    nvim-surround = pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "nvim-surround";
      src = pkgs.fetchFromGitHub {
        owner = "kylechui";
        repo = "nvim-surround";
        rev = "78f10536d30a4f86155354636335263a0e6a7891";
        sha256 = "sha256-lShnjQF1NcVWD6h2XK5QJyTzPLeriO6r/DcqP1Cx9RA=";
      };
      version = "unstable-2022-07-19";
    };
  });
}
