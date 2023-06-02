final: prev:

let
  inherit (prev) callPackage;
in

{
  simp1e-cursors = callPackage ./simp1e-cursors { };
  umc = callPackage ./umc { };
  wlr-spanbg = callPackage ./wlr-spanbg { };
  bgrep = callPackage ./bgrep { };

  wayfire-git = callPackage ./wayfire { };
  wayfirePlugins = prev.wayfirePlugins // {
    dbus-interface = callPackage ./wayfire/wayfirePlugins/wayfire-dbus { wayfire = final.wayfire-git; };
    firedecor = callPackage ./wayfire/wayfirePlugins/firedecor { wayfire = final.wayfire-git; };
    plugins-extra = callPackage ./wayfire/wayfirePlugins/wayfire-plugins-extra { wayfire = final.wayfire-git; };
    shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { wayfire = final.wayfire-git; };
  };

  mpvScripts = prev.mpvScripts // {
    osc-tethys = callPackage ./mpv/scripts/osc-tethys { };
    mfpbar = callPackage ./mpv/scripts/mfpbar { };
  };

  opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

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
}
