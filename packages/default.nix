final: prev:

let
  inherit (prev) callPackage;
in

rec {
  firefox-custom = callPackage ./firefox { };
  nerdfonts-patch = callPackage ./nerdfonts-patch { };
  simp1e-cursor-theme = callPackage ./simp1e-cursor-theme { };
  umc = callPackage ./umc { };
  wlopm = callPackage ./wlopm { };
  wlr-spanbg = callPackage ./wlr-spanbg { };
  git-credential-keepassxc = callPackage ./git-credential-keepassxc { };

  wayfire-git = callPackage ./wayfire { };
  wayfirePlugins = prev.wayfirePlugins // {
    dbus-interface = callPackage ./wayfire/wayfirePlugins/wayfire-dbus { wayfire = wayfire-git; };
    firedecor = callPackage ./wayfire/wayfirePlugins/firedecor { wayfire = wayfire-git; };
    plugins-extra = callPackage ./wayfire/wayfirePlugins/wayfire-plugins-extra { wayfire = wayfire-git; };
    shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { wayfire = wayfire-git; };
  };

  iosevka-custom = prev.iosevka.override {
    privateBuildPlan = {
      family = "Iosevka Custom";
      spacing = "normal";
      serifs = "sans";
      no-cv-ss = true;
      no-litigation = true;
    };
    set = "custom";
  };
  iosevka-nerdfonts = nerdfonts-patch iosevka-custom;

  opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

  vimPlugins = prev.vimPlugins // {
    heirline-nvim = prev.vimUtils.buildVimPluginFrom2Nix {
      pname = "heirline-nvim";
      src = prev.fetchFromGitHub {
        owner = "rebelot";
        repo = "heirline.nvim";
        rev = "9179b71d9967057814e5920ecb3c8322073825ea";
        sha256 = "sha256-5IkZ+NfecFomQbDlz71YpbxNB2v9Y+i8Kkjyv4Mhr3Y=";
      };
      version = "unstable-2022-09-22";
    };
    hlargs-nvim = prev.vimUtils.buildVimPluginFrom2Nix {
      pname = "hlargs-nvim";
      src = prev.fetchFromGitHub {
        owner = "m-demare";
        repo = "hlargs.nvim";
        rev = "f674e11304be45e4d1cae103af5275c0b2ea7b4c";
        sha256 = "sha256-8TbtM6nyMziBGJy/T4xjQbYq9i/kYizwB12POA4CUuw=";
      };
      version = "unstable-2022-09-29";
    };
  };
}
