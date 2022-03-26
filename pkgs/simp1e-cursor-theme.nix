{ fetchFromGitLab, lib, librsvg, python3Packages, stdenvNoCC,
# Add your own theme by overriding the `theme` argument:
# theme = {
#   name = "Simp1e Kanagawa";
#   shadow_opacity = 0.35;
#   shadow = "#2E3440";
#   cursor_border = "#DCD7BA";
#   default_cursor_bg = "#1F1F28";
#   hand_bg = "#1F1F28";
#   question_mark_bg = "#88C0D0";
#   question_mark_fg = "#434C5E";
#   plus_bg = "#A3BE8C";
#   plus_fg = "#434C5E";
#   link_bg = "#B48EAD";
#   link_fg = "#434C5E";
#   move_bg = "#D08770";
#   move_fg = "#434C5E";
#   context_menu_bg = "#81A1C1";
#   context_menu_fg = "#434C5E";
#   forbidden_bg = "#434C5E";
#   forbidden_fg = "#BF616A";
#   magnifier_bg = "#434C5E";
#   magnifier_fg = "#D8DEE9";
#   skull_bg = "#434C5E";
#   skull_eye = "#D8DEE9";
#   spinner_bg = "#434C5E";
#   spinner_fg1 = "#D8DEE9";
#   spinner_fg2 = "#D8DEE9";
# };
theme ? null, xcursorgen }:

stdenvNoCC.mkDerivation {
  pname = "simp1e-cursor-theme";
  version = "unstable-2022-03-18";

  src = fetchFromGitLab {
    owner = "zoli111";
    repo = "simp1e";
    rev = "f3aa2abe9db94cba3c87b0bb6651fac656d30e3e";
    hash = "sha256-Nq2A8TB1o17993ozlrR5vuMj1qMeSeh3n04KaQjG1/E=";
    fetchSubmodules = true;
  };

  phases = [ "unpackPhase" "preBuildPhase" "buildPhase" "installPhase" ];

  nativeBuildInputs = [ librsvg python3Packages.pillow xcursorgen ];

  preBuildPhase = let
    fileName = builtins.replaceStrings [ " " ] [ "-" ] theme.name;
    fileContents = lib.concatStringsSep "\n" (lib.mapAttrsToList
      (variableName: value:
        "${variableName}=\"${ lib.removePrefix "#" (lib.generators.mkValueStringDefault { } value) }\"") theme);
  in lib.optionalString (builtins.isAttrs theme) ''
    echo ${lib.escapeShellArg fileContents} > ./src/color_schemes/${fileName}.sh
  '';

  buildPhase = ''
    for builder in ./generate_svgs.sh ./build_cursors.sh; do
      patchShebangs --build "$builder"
      bash -c "$builder"
    done
  '';

  installPhase = ''
    mkdir -p "$out/share/icons"
    for theme in ./built_themes/*; do
      cp -r "$theme" "$out/share/icons/"
    done
  '';

  meta = with lib; {
    description = "An aesthetic cursor theme for your Linux desktop";
    homepage = "https://gitlab.com/zoli111/simp1e";
    platforms = platforms.unix;
    license = licenses.gpl3Only;
  };
}
