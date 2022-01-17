{ pkgs, lib, colors, ... }:


let
  toCSSRGB = hex: "rgb(${
    lib.concatMapStringsSep ", "
      (num: toString num)
      (lib.extended.colour.utils.toRGB hex)
    })";
  mkBrootSkin = { ... }@args:
    lib.mapAttrs (name: value:
      if lib.any (x: x == "active" || x == "inactive") (builtins.attrNames value) then
        "${
          let c = value.active.fg or "None";
          in if c != "None" then toCSSRGB c else "None"
        } ${
          value.active.bg or "None"
        } ${
          value.active.styles or ""
        } / ${
          value.inactive.fg or "None"
        } ${
          value.inactive.bg or "None"
        } ${
          value.inactive.styles or "None"
        }"
      else
        "${value.fg or "None"} ${value.bg or "None"} ${value.styles or ""}"
    )
    args;
in
with lib.extended.colour;
{
  programs.broot.skin = mkBrootSkin {
    default = {
      active.fg = background.front;
      inactive.fg = background.back;
    };
    preview_title = "gray(20) rgb(0, 43, 54)";
    preview = "gray(20) rgb(40, 0, 0)";
  };
}
