final: prev:

let
  callPackage = prev.lib.callPackageWith (prev // packages);
  packages = {
    bgrep = callPackage ./bgrep { };

    camera-streamer = callPackage ./camera-streamer { libcamera = packages.libcamera-rpi; };

    libcamera-apps = callPackage ./libcamera-apps { libcamera = packages.libcamera-rpi; };

    libcamera-rpi = prev.libcamera.overrideAttrs (old: {
      version = "0.1.0";
      src = old.src.override {
        rev = "v0.1.0";
        hash = "sha256-icHZtv25QvJEv0DlELT3cDxho3Oz2BJAMNKr5W4bshk=";
      };
      mesonFlags = old.mesonFlags ++ [
        "-Dipas=rpi/vc4"
        "-Dpipelines=rpi/vc4"
      ];
    });

    mpvScripts = prev.mpvScripts // {
      osc-tethys = callPackage ./mpv/scripts/osc-tethys { };

      mfpbar = callPackage ./mpv/scripts/mfpbar { };
    };

    opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

    pineflash = callPackage ./pineflash { };

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
      dbus-interface = callPackage ./wayfire/wayfirePlugins/wayfire-dbus { wayfire = packages.wayfire-git; };

      firedecor = callPackage ./wayfire/wayfirePlugins/firedecor { wayfire = packages.wayfire-git; };

      plugins-extra = callPackage ./wayfire/wayfirePlugins/wayfire-plugins-extra { wayfire = packages.wayfire-git; };

      shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { wayfire = packages.wayfire-git; };
    };

    wlr-spanbg = callPackage ./scripts/wlr-spanbg { };

    mountImage = callPackage ./scripts/mountImage.nix { };

    qr = callPackage ./scripts/qr.nix { };
  };
in
  packages
