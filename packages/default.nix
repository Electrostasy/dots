final: prev:

let
  callPackage = prev.lib.callPackageWith (prev // packages);
  packages = {
    bgrep = callPackage ./bgrep { };

    camera-streamer = callPackage ./camera-streamer { libcamera = packages.libcamera-rpi; };

    rpicam-apps = callPackage ./rpicam-apps { libcamera = packages.libcamera-rpi; };

    libcamera-rpi = prev.libcamera.overrideAttrs (newAttrs: oldAttrs: {
      version = "v0.1.0+rpt20231122";

      src = prev.fetchFromGitHub {
        owner = "raspberrypi";
        repo = oldAttrs.pname;
        rev = newAttrs.version;
        hash = "sha256-T5MBTTYaDfaWEo/czTE822e5ZXQmcJ9pd+RWNoM4sBs=";
      };

      patches = [];

      mesonFlags = (oldAttrs.mesonFlags or []) ++ [
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

    wayfirePlugins = prev.wayfirePlugins // {
      shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { };
    };

    wlr-spanbg = callPackage ./scripts/wlr-spanbg { };

    mountImage = callPackage ./scripts/mountImage.nix { };

    qr = callPackage ./scripts/qr.nix { };
  };
in
  packages
