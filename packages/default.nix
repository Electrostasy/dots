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
        version = "unstable-2023-07-05";

        src = prev.fetchFromGitHub {
          owner = "m-demare";
          repo = "hlargs.nvim";
          rev = "cfc9beab4e176a13311efe03e38e6b6fed5df4f6";
          hash = "sha256-Mw5HArqBL6Uc1D3TVOSwgG0l2vh0Xq3bO170dkrJbwI=";
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
