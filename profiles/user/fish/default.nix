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
          argparse -x e,d -x e,c 'e/encode' 'd/decode' 'c/camera' -- $argv
          if set -q _flag_encode
            # If stdin is used, encode that instead of clipboard
            set -l text
            if isatty stdin
              set text (${pkgs.wl-clipboard}/bin/wl-paste)
              if test $status -ne 0
                return 1
              end
            else
              read text
            end
            echo $text | ${pkgs.qrencode}/bin/qrencode -t ansiutf8
            return 0
          end
          if set -q _flag_decode
            if set -q _flag_camera
              if not test -e /dev/video0
                echo "qr: video4linux device at /dev/video0 not found!"
                return 1
              end
              ${pkgs.zbar}/bin/zbarcam -Sqrcode.enable --raw --prescale=320x240 -1
              return 0
            end
            ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) - | ${pkgs.zbar}/bin/zbarimg -q --raw PNG:
            return 0
          end
          echo 'Usage:'
          echo '  -e/--encode: encode one of clipboard or from stdin'
          echo '  -d/--decode: decode selected region'
          echo '  -c/--camera: decode from camera instead of region'
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
