{ config, pkgs, lib, ... }:

let
  cfg = config.programs.command-not-found;
in

{
  disabledModules = [ "programs/command-not-found/command-not-found.nix" ];

  options.programs.command-not-found = {
    enable = lib.mkEnableOption ''
      interactive shells showing which Nix package (if any) provides a missing
      command.

      Requires either nix-channels to be set and downloaded (sudo nix-channels
      --update) or the nixpkgs flake input set to a lockable tarball
      (https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz)'' // { default = true; };

    dbPath = lib.mkOption {
      default = "${pkgs.path}/programs.sqlite";
      description = ''
        Absolute path to programs.sqlite.

        By default this file will be provided by your channel or nixpkgs tarball (nixexprs.tar.xz).
      '';
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash.interactiveShellInit = /* bash */ ''
      command_not_found_handle() {
        if [[ ! -e '${cfg.dbPath}' ]]; then
          echo '${cfg.dbPath} is missing!'
          echo 'Please set programs.command-not-found.dbPath in your NixOS configuration to where programs.sqlite is.'
          echo 'You can disable this feature by setting programs.command-not-found.enable to false in your NixOS configuration.'
          return 127
        fi

        mapfile -t packages < <(${lib.getExe pkgs.sqlite} '${cfg.dbPath}' "SELECT DISTINCT package FROM Programs WHERE name = '$1';")
        amount=''${#packages[@]}

        output="The program '$1' is not in your PATH. "

        if [[ $amount -eq 0 ]]; then
          output+='It is not provided by any indexed packages.'
        else
          maybe_one_of=
          if [[ $amount -eq 1 ]]; then
            output+='It is provided by one package.\n'
          else
            output+='It is provided by several packages.\n'
            maybe_one_of=' one of'
          fi

          output+="You can make it available in an ephemeral shell by typing$maybe_one_of the following:\n"
          output+="$(printf '  nix shell nixpkgs#%s\n' "''${packages[@]}")\n\n"
          output+="You can run it once by typing$maybe_one_of the following:\n"
          output+="$(printf '  nix run nixpkgs#%s\n' "''${packages[@]}")"
        fi

        printf '%b' "$output"
      }
    '';

    # INFO: I don't use zsh.
    # programs.zsh.interactiveShellInit = ''
    #   command_not_found_handler() {
    #   }
    # '';

    programs.fish.interactiveShellInit = /* fish */ ''
      function fish_command_not_found
        if not test -e ${cfg.dbPath}
          echo '${cfg.dbPath} is missing!'
          echo 'Please set programs.command-not-found.dbPath in your NixOS configuration to where programs.sqlite is.'
          echo 'You can disable this feature by setting programs.command-not-found.enable to false in your NixOS configuration.'
          return 127
        end

        set -l packages (${lib.getExe pkgs.sqlite} '${cfg.dbPath}' "SELECT DISTINCT package FROM Programs WHERE name = '$argv[1]';")
        set -l amount (count $packages)

        set -l output "The program '$(set_color $fish_color_error; echo -n $argv[1]; set_color normal)' is not in your PATH. "

        if test $amount -eq 0
          set -a output 'It is not provided by any indexed packages.\n'
        else
          if test $amount -eq 1
            set -a output 'It is provided by one package.\n'
          else
            set -a output 'It is provided by several packages.\n'
            set -l maybe_one_of ' one of'
          end

          set -a output \
            "You can make it available in an ephemeral shell by typing$maybe_one_of the following:\n" \
            "$(printf '  nix shell nixpkgs#%s\n' $packages | fish_indent --ansi --only-unindent)" '\n\n' \
            "You can run it once by typing$maybe_one_of the following:\n" \
            "$(printf '  nix run nixpkgs#%s\n' $packages | fish_indent --ansi --only-unindent)" '\n'
        end

        printf '%b' $output
      end
    '';
  };
}
