{ config, pkgs, lib, colors, ... }:

let
  cfg = config.programs.fish;
  noPoundColors = builtins.mapAttrs
    (name: value:
      builtins.replaceStrings [ "#" ] [ "" ] value
    )
    colors;
in

with noPoundColors;

{
  programs.fish.interactiveShellInit = lib.mkIf cfg.enable ''
    set -U fish_color_autosuggestion      ${sumiInk4}
    set -U fish_color_cancel              -r
    set -U fish_color_command             ${crystalBlue}
    set -U fish_color_comment             ${fujiGray}
    set -U fish_color_cwd                 green
    set -U fish_color_cwd_root            red
    set -U fish_color_end                 brmagenta
    set -U fish_color_error               ${samuraiRed}
    set -U fish_color_escape              ${boatYellow2}
    set -U fish_color_history_current     --bold
    set -U fish_color_host                normal
    set -U fish_color_match               --background=brblue
    set -U fish_color_normal              ${fujiWhite}
    set -U fish_color_operator            ${boatYellow2}
    set -U fish_color_param               ${oniViolet}
    set -U fish_color_quote               ${springGreen}
    set -U fish_color_redirection         ${springBlue}
    set -U fish_color_search_match        'bryellow' '--background=brblack'
    set -U fish_color_selection           'white' '--bold' '--background=brblack'
    set -U fish_color_status              red
    set -U fish_color_user                brgreen
    set -U fish_color_valid_path          --underline
    set -U fish_pager_color_completion    normal
    set -U fish_pager_color_description   yellow
    set -U fish_pager_color_prefix        'white' '--bold' '--underline'
    set -U fish_pager_color_progress      'brwhite' '--background=cyan'
  '';
}
