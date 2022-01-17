{ pkgs, lib, colors, ... }:

with colors;

{
  programs.kitty.settings = {
    # background_opacity = "0.9";
    window_padding_width = 2;

    foreground = fujiWhite;
    background = sumiInk1;
    # Black
    color0 = sumiInk0;
    color8 = fujiGray;
    # Red
    color1 = autumnRed;
    color9 = samuraiRed;
    # Green
    color2 = autumnGreen;
    color10 = springGreen;
    # Yellow
    color3 = boatYellow1;
    color11 = carpYellow;
    # Blue
    color4 = crystalBlue;
    color12 = springBlue;
    # Magenta
    color5 = oniViolet;
    color13 = springViolet1;
    # Cyan
    color6 = waveAqua1;
    color14 = waveAqua2;
    # White
    color7 = oldWhite;
    color15 = fujiWhite;
    # Extended colours
    color16 = surimiOrange;
    color17 = peachRed;
    # Cursor
    cursor = oldWhite;
    # cursor_text_color = sumiInk1;
    # Selection highlight
    selection_background = waveBlue2;
    selection_foreground = oldWhite;
    # Colour for highlighting URLs on mouse over
    url_color = "#72a7bc";

    # Tabs
    active_tab_background = waveBlue2;
    active_tab_foreground = fujiWhite;
    inactive_tab_background = waveBlue1;
    inactive_tab_foreground = fujiGray;
  };
}
