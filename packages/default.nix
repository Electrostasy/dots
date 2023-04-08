final: prev:

let
  inherit (prev) callPackage;
in

{
  simp1e-cursors = callPackage ./simp1e-cursors { };
  umc = callPackage ./umc { };
  wlr-spanbg = callPackage ./wlr-spanbg { };
  bgrep = callPackage ./bgrep { };
  weathercrab = callPackage ./weathercrab { };

  wayfire-git = callPackage ./wayfire { };
  wayfirePlugins = prev.wayfirePlugins // {
    dbus-interface = callPackage ./wayfire/wayfirePlugins/wayfire-dbus { wayfire = final.wayfire-git; };
    firedecor = callPackage ./wayfire/wayfirePlugins/firedecor { wayfire = final.wayfire-git; };
    plugins-extra = callPackage ./wayfire/wayfirePlugins/wayfire-plugins-extra { wayfire = final.wayfire-git; };
    shadows = callPackage ./wayfire/wayfirePlugins/wayfire-shadows { wayfire = final.wayfire-git; };
  };

  mpvScripts = prev.mpvScripts // {
    uosc = callPackage ./mpv/scripts/uosc { };
    thumbfast = callPackage ./mpv/scripts/thumbfast { };
    osc-tethys = callPackage ./mpv/scripts/osc-tethys { };
    mfpbar = callPackage ./mpv/scripts/mfpbar { };
  };

  opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

  vimPlugins = prev.vimPlugins.extend (final': prev': {
    hlargs-nvim = prev.vimUtils.buildVimPlugin {
      pname = "hlargs-nvim";
      version = "unstable-2023-03-06";

      src = prev.fetchFromGitHub {
        owner = "m-demare";
        repo = "hlargs.nvim";
        rev = "a7ad6ed8d6e27ea4dd13fda63fa732e9196ba4ea";
        sha256 = "sha256-9kCQs1IFt48Y3IWClFlwdT/Kbgv93gPEdhGi75k04qU=";
      };
    };
  });
}
