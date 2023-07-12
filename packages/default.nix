final: prev:

let
  callPackage = prev.lib.callPackageWith (prev // packages);
  packages = {
    bgrep = callPackage ./bgrep { };

    blisp = callPackage ./blisp { };

    libcamera-apps = callPackage ./libcamera-apps { libcamera = final.libcamera-rpi; };

    libcamera-rpi = prev.libcamera.overrideAttrs (old: {
      mesonFlags = old.mesonFlags ++ [
        "-Dipas=raspberrypi"
        "-Dpipelines=raspberrypi"
      ];
    });

    mpvScripts = prev.mpvScripts // {
      osc-tethys = callPackage ./mpv/scripts/osc-tethys { };

      mfpbar = callPackage ./mpv/scripts/mfpbar { };
    };

    opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

    pineflash = callPackage ./pineflash { };

    qr = callPackage ./qr { };

    simp1e-cursors = callPackage ./simp1e-cursors { };

    umc = callPackage ./umc { };

    vimPlugins = prev.vimPlugins.extend (final': prev': {
      hlargs-nvim = prev.vimUtils.buildVimPlugin {
        pname = "hlargs-nvim";
        version = "unstable-2023-05-24";

        src = prev.fetchFromGitHub {
          owner = "m-demare";
          repo = "hlargs.nvim";
          rev = "bd16884ef4dd3553550313d767505a0f44a3a852";
          hash = "sha256-a3xno1tU59pKSusdg2jyZsRuGeaFBAWlLZ+fZe0nCGA=";
        };
      };
    });

    wayfire-git = callPackage ./wayfire { };

    wayfirePlugins = prev.wayfirePlugins // {
      dbus-interface = callPackage ./wayfire/wayfirePlugins/wayfire-dbus { wayfire = final.wayfire-git; };

      firedecor = callPackage ./wayfire/wayfirePlugins/firedecor { wayfire = final.wayfire-git; };

      plugins-extra = callPackage ./wayfire/wayfirePlugins/wayfire-plugins-extra { wayfire = final.wayfire-git; };

      shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { wayfire = final.wayfire-git; };
    };

    wlr-spanbg = callPackage ./wlr-spanbg { };
  };
in
  packages
