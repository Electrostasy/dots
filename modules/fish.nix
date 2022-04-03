{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases.ssh = lib.mkIf config.programs.kitty.enable "kitty +kitten ssh";
    functions = {
      qr = {
        description = ''
          Encode clipboard contents as a QR code, or decode a QR code from selected screen region
        '';
        body = ''
          argparse -x e,d 'e/encode' 'd/decode' -- $argv
          if set -q _flag_encode
            echo (${pkgs.wl-clipboard}/bin/wl-paste) | ${pkgs.qrencode}/bin/qrencode -t ansiutf8
            return 0
          end
          if set -q _flag_decode
            ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) - | ${pkgs.zbar}/bin/zbarimg -q --raw PNG:
            return 0
          end
          echo 'Usage:'
          echo '  -e/--encode: encode clipboard'
          echo '  -d/--decode: decode selected region'
          return 1
        '';
      };
      fish_greeting = ''
        if isatty stdout
          set_color $fish_color_comment
        end; ${pkgs.fortune}/bin/fortune definitions
      '';
    };
    plugins = [{
      name = "fzf.fish";
      inherit (pkgs.fishPlugins.fzf-fish) src;
    }];
    interactiveShellInit = ''
      source ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.fish
    '';
  };

  home.packages = with pkgs; [
    fzf
    fd
    bat
  ];
}
