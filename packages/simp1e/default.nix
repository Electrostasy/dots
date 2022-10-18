{
  fetchFromGitLab,
  lib,
  librsvg,
  makeFontsConf,
  python3Packages,
  stdenvNoCC,
  xcursorgen,

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
  theme ? null,

  withPreviews ? true
}:

let
  cursorGenerator = fetchFromGitLab {
    owner = "cursors";
    repo = "cursor-generator";
    rev = "634d768bbe62dd198e77392328918a5b9b4dd72d";
    hash = "sha256-gwRZYhp/HcfRSk6HeS0NyVVNGiZHHtHMAgVdxj+ofBI=";
  };

  buildCustomTheme = let
    name = builtins.replaceStrings [ " " ] [ "-" ] theme.name;
    contents =
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (variableName: value:
          "${variableName}:${ lib.removePrefix "#" (lib.generators.mkValueStringDefault { } value) }") theme);
  in ''
    echo ${lib.escapeShellArg contents} > ./src/color_schemes/Simp1e-${name}.txt
  '';
in

stdenvNoCC.mkDerivation {
  pname = "simp1e";
  version = "unstable-2022-10-17";

  src = fetchFromGitLab {
    owner = "cursors";
    repo = "simp1e";
    rev = "6cee39b75902998e375590810a952b8771bb3bf1";
    hash = "sha256-AAN56mnjl5gAzVF8yI7e/b1xanAo9TtHrR4CKqaEfhY=";
  };

  dontConfigure = true;
  dontFixup = true;

  nativeBuildInputs = [
    librsvg
    python3Packages.pillow
    xcursorgen
  ];

  # Complains about not being able to find the fontconfig config file otherwise
  FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

  buildPhase = ''
    ${lib.optionalString (builtins.isAttrs theme) buildCustomTheme}

    # Resolves the warning "Fontconfig error: No writable cache directories"
    export XDG_CACHE_HOME="$(mktemp -d)"

    # Can't symlink or else sed can't open its temporary files
    cp -r ${cursorGenerator}/* ./cursor-generator

    patchShebangs ./build.sh ./cursor-generator/generator.sh ./cursor-generator/make.py

    ./build.sh ${lib.optionalString withPreviews "-p"}
  '';

  installPhase = ''
    mkdir -p "$out/share/icons"
    find ./built_themes -mindepth 1 -maxdepth 1 -type d -exec cp -r {} $out/share/icons/ \;
  '';

  meta = with lib; {
    description = "An aesthetic cursor theme for Linux desktops";
    homepage = "https://gitlab.com/cursors/simp1e";
    platforms = platforms.unix;
    license = licenses.gpl3Only;
  };
}
