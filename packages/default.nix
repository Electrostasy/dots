{ pkgs, lib, flake }:

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

  vimPlugins = lib.makeScope pkgs.newScope (self:
    let
      mkVimPlugin = pname:
        pkgs.vimUtils.buildVimPlugin {
          inherit pname;
          src = flake.inputs.${pname};
          version = let
            date = flake.inputs.${pname}.lastModifiedDate;
            year = builtins.substring 0 4 date;
            month = builtins.substring 4 2 date;
            day = builtins.substring 6 2 date;
          in "unstable-${year}-${month}-${day}";
        };
      mkVimPlugins = pnames:
        lib.foldl lib.recursiveUpdate { }
        (builtins.map (pname: { ${pname} = mkVimPlugin pname; }) pnames);
    in
      mkVimPlugins [
        "fzf-lua"
        "heirline-nvim"
        "hlargs-nvim"
      ]
    );
}
