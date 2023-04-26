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
    uosc = callPackage ./mpv/scripts/uosc { };
    thumbfast = callPackage ./mpv/scripts/thumbfast { };
    osc-tethys = callPackage ./mpv/scripts/osc-tethys { };
    mfpbar = callPackage ./mpv/scripts/mfpbar { };
  };

  opensmtpd-filter-senderscore = callPackage ./opensmtpd-senderscore { };

  vimPlugins = prev.vimPlugins.extend (final': prev': {
    hlargs-nvim = prev.vimUtils.buildVimPlugin {
      pname = "hlargs-nvim";
      version = "unstable-2023-04-11";

      src = prev.fetchFromGitHub {
        owner = "m-demare";
        repo = "hlargs.nvim";
        rev = "d25d8049f451704e4a06836a602e0f8947ef9fcb";
        sha256 = "sha256-w2IQefpD7NAxrnOcl/v9KkFqg93XkVc8RSOOWp7OWZw=";
      };
    };
  });
}
