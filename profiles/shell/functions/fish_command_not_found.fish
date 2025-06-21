function fish_command_not_found
	set -l packages (@sqlite@/bin/sqlite3 @path@/programs.sqlite "SELECT DISTINCT package FROM Programs WHERE name = '$argv[1]';")
	set -l plural_text (test (count $packages) -gt 1; and echo -n ' one of')

	set -l command (set_color $fish_color_error; printf $argv[1]; set_color $fish_color_normal)
	set -l output "The program '$(hyperlink "https://search.nixos.org/packages?channel=unstable&query=$argv[1]" $command)' is not in your PATH."
	if set -q packages[1]
		if test (count $packages) -eq 1
			set -a output 'It is provided by one package.'
		else
			set -a output 'It is provided by several packages.'
		end

		set -a output "\nYou can make it available in an ephemeral shell by typing$plural_text the following:\n"
		set -a output ' '(printf 'nix shell nixpkgs#%s\n' $packages | fish_indent --ansi)\n
		set -e output[-1] # remove the final newline.

		# FIXME: We shouldn't need set_color here, some escape probably got cut.
		set -a output (set_color $fish_color_normal; echo -n "\nYou can run it once by typing$plural_text the following:\n")
		set -a output ' '(printf 'nix run nixpkgs#%s\n' $packages | fish_indent --ansi)\n
		set -e output[-1] # remove the final newline.
	else
		set -a output 'It is not provided by any indexed packages.\n'
	end

	echo -en $output
end
