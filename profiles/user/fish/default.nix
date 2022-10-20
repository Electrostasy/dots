{ config, pkgs, lib, ... }:

{
  programs.nix-index = {
    enable = true;

    # We use our own command not found handler in programs.fish.shellInit
    enableFishIntegration = lib.mkDefault false;
  };

  programs.fish = {
    enable = true;

    shellAliases.ssh = lib.mkIf config.programs.kitty.enable "kitty +kitten ssh";

    functions.qr = {
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

    shellInit = ''
      function __fish_command_not_found_handler --on-event fish_command_not_found
        set -l query $argv[1]
        set -l attrs (nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$query")
        set attrs (string replace '.out' '''''' $attrs | string collect | sort)

        echo -n "The program '"
        set_color $fish_color_error; echo -n "$query"

        if string trim $attrs | string length --quiet
          set_color $fish_color_normal; echo -n "' is not installed."
        else
          set_color $fish_color_normal; echo "' could not be located."
          return 127
        end

        if [ (count $attrs) -gt 1 ]
          echo " It is provided by several packages."
        else
          echo ""
        end
        echo -n "Spawn a shell containing '"
        set_color $fish_color_error; echo -n "$query"
        set_color $fish_color_normal; echo "':"

        for attr in $attrs
          echo -n "  $(echo "nix shell nixpkgs#$attr" | fish_indent --ansi --no-indent)"
        end
        echo -e "\nOr run it once with:"
        for attr in $attrs
          echo -n "  $(echo "nix run nixpkgs#$attr" | fish_indent --ansi --no-indent)"
        end

        set_color $fish_color_normal
      end

      function fish_greeting
        if isatty stdout
          set_color $fish_color_comment
        end
        ${pkgs.fortune}/bin/fortune definitions
      end
    '';

    interactiveShellInit = ''
      # kanagawa.nvim fish shell theme with exported fish_color_* variables.
      # Necessary in order to access them in functions and scripts.
      set -l foreground DCD7BA
      set -l selection 2D4F67
      set -l comment 727169
      set -l red C34043
      set -l orange FF9E64
      set -l yellow C0A36E
      set -l green 76946A
      set -l purple 957FB8
      set -l cyan 7AA89F
      set -l pink D27E99

      # Syntax Highlighting Colors
      set -gx fish_color_normal $foreground
      set -gx fish_color_command $cyan
      set -gx fish_color_keyword $pink
      set -gx fish_color_quote $yellow
      set -gx fish_color_redirection $foreground
      set -gx fish_color_end $orange
      set -gx fish_color_error $red
      set -gx fish_color_param $purple
      set -gx fish_color_comment $comment
      set -gx fish_color_selection --background=$selection
      set -gx fish_color_search_match --background=$selection
      set -gx fish_color_operator $green
      set -gx fish_color_escape $pink
      set -gx fish_color_autosuggestion $comment

      # Completion Pager Colors
      set -gx fish_pager_color_progress $comment
      set -gx fish_pager_color_prefix $cyan
      set -gx fish_pager_color_completion $foreground
      set -gx fish_pager_color_description $comment
    '';
  };
}
