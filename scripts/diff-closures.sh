#!/usr/bin/env bash

function is_derivation {
	nix path-info --derivation "$1" &> /dev/null
}

function is_flake {
	nix flake info "${1%%#*}" &> /dev/null
}

function print_usage {
	echo "USAGE:"
	echo "  $0 <before> <after>"
}

function format_size {
	local integer="${1:-0}"
	local decimal=''
	local units=(Bytes {K,M,G,T,E,P,Y,Z}iB)

	for ((i=0; integer > 1024; ++i)); do
		decimal="$(printf '.%02d' "$((integer % 1024 * 100 / 1024))")"
		integer="$((integer / 1024))"
	done

	echo "$integer$decimal ${units[$i]}"
}

function concat_strings_sep {
	local sep="$1"
	local -n array=$2

	local length="${#array[@]}"
	if [[ $length -gt 1 ]]; then
		printf "%s$sep" "${array[@]::$length-1}"
	fi

	if [[ $length -gt 0 ]]; then
		printf '%s' "${array[-1]}"
	fi
}

function println_green {
	printf '\x1B[0;32m%s\x1B[0m\n' "$1"
}

function println_red {
	printf '\x1B[0;31m%s\x1B[0m\n' "$1"
}

function println_blue {
	printf '\x1B[0;34m%s\x1B[0m\n' "$1"
}

function println_brblue {
	printf '\x1B[0;94m%s\x1B[0m\n' "$1"
}

# If our arguments are not derivations, check if they are shorthand for a NixOS
# configuration and rewrite them, otherwise print usage instructions.
before_closure="${1:-/run/current-system}"
if ! is_derivation "$before_closure" && is_flake "$before_closure"; then
	before_closure="${1%%#*}#nixosConfigurations.\"${1##*#}\".config.system.build.toplevel"
	if ! is_derivation "$before_closure"; then
		print_usage
		exit 1
	fi
fi

after_closure="${2:-/etc/nixos#nixosConfigurations.\"$HOSTNAME\".config.system.build.toplevel}"
if ! is_derivation "$after_closure" && is_flake "$after_closure"; then
	after_closure="${1%%#*}#nixosConfigurations.\"${1##*#}\".config.system.build.toplevel"
	if ! is_derivation "$after_closure"; then
		print_usage
		exit 1
	fi
fi

# If our second argument is a flakeref pointing to a NixOS configuration, we
# can sort packages into those that are part of `environment.systemPackages`
# and those that are not.
declare -A environment_system_packages
if is_flake "$after_closure" && [[ "$after_closure" == *.system.build.toplevel ]]; then
	pkgs="${after_closure%%.system.build.toplevel}.environment.systemPackages"

	while read -r pname; do
		environment_system_packages["$pname"]=0
	done < <(nix eval --raw "$pkgs" --apply 'pkgs: builtins.concatStringsSep "\n" (builtins.map (x: x.pname) (builtins.filter (x: x ? pname) pkgs))')
fi

# https://github.com/NixOS/nix/blob/master/src/nix/diff-closures.md
while read -r line; do
	# `nix store diff-closures` does not respect neither `NO_COLOR=1` or
	# `TERM=DUMB` to disable colours, so we have to remove all ANSI colour
	# codes ourselves:
	# https://github.com/NixOS/nix/issues/5214
	# https://github.com/NixOS/nix/pull/5090
	# https://github.com/NixOS/nix/pull/4971
	# Colours need to be removed since the escape sequences make globbing
	# really painful.
	shopt -s extglob
	line="${line//$'\x1B'[\[(]*([0-9;])[@-n]/}"
	shopt -u extglob

	# In order to make parsing by delimiters easier, we also strip all
	# whitespace from the line.
	line="${line//[[:blank:]]/}"

	package="${line%:*}"
	rest="${line#*:}"

	# Skip packages whose closures only changed in size.
	if [[ "$rest" != *→* ]]; then
		continue
	fi

	unset 'left_fields'
	while IFS=',' read -ra fields; do
		for field in "${fields[@]}"; do
			case "$field" in
				# Epsilon means there is no version
				# information, it is likely not a normal
				# package (like a systemd service unit), so
				# skip the entire line.
				'ε') continue 3 ;;

				# Null set means this is an added package, and
				# there is nothing on the left side of the
				# arrow besides this, so skip the rest of the
				# fields.
				'∅') continue 2 ;;

				# Do not show fish completions that were
				# generated for packages.
				*_fish) ;;

				*) left_fields+=("$field") ;;
			esac
		done
	done < <(echo "${rest%→*}")

	unset 'size'
	unset 'right_fields'
	while IFS=',' read -ra fields; do
		for field in "${fields[@]}"; do
			case "$field" in
				# Epsilon means there is no version
				# information, it is likely not a normal
				# package (like a systemd service unit), so
				# skip the entire line.
				'ε') continue 3 ;;

				# Null set means this is a removed package, and
				# there is nothing on the right side of the
				# arrow besides potentially size, so we skip
				# this field, but not all of the fields.
				'∅') ;;

				# Do not show fish completions that were
				# generated for packages.
				*_fish) ;;

				# If the field looks like a size field, and it
				# is a size field, re-format it, store the
				# value and skip the field.
				*KiB)
					if [[ "$field" =~ ([+-])([0-9\.]+) ]]; then
						sign="${BASH_REMATCH[1]}"
						value="$(format_size $((${BASH_REMATCH[2]/./} * 1024 / 10)))"
						case "$sign" in
							'+') size=" ($(println_red "$sign$value"))" ;;
							'-') size=" ($(println_green "$sign$value"))" ;;
						esac
					fi
					;;

				*) right_fields+=("$field") ;;
			esac
		done
	done < <(echo "${rest#*→}")

	left="$(concat_strings_sep ', ' left_fields)"
	right="$(concat_strings_sep ', ' right_fields)"

	if [[ ${#left_fields[@]} -eq 0 ]]; then
		added_pkgs+=("$(println_green "$package"): $right$size")
		continue
	fi

	if [[ ${#right_fields[@]} -eq 0 ]]; then
		removed_pkgs+=("$(println_red "$package"): $left$size")
		continue
	fi

	if [[ -v environment_system_packages[$package] ]]; then
		environment_pkgs+=("$(println_brblue "$package"): $left → $right$size")
	else
		other_pkgs+=("$(println_blue "$package"): $left → $right$size")
	fi
done < <(nix store diff-closures "$before_closure" "$after_closure")

if [[ -v added_pkgs ]]; then
	echo "${#added_pkgs[@]} added packages:"
	printf '  %s\n' "${added_pkgs[@]}"
fi

if [[ -v removed_pkgs ]]; then
	if [[ -v added_pkgs ]]; then
		echo
	fi
	echo "${#removed_pkgs[@]} removed packages:"
	printf '  %s\n' "${removed_pkgs[@]}"
fi

num_changed_pkgs="$((${#environment_pkgs[@]} + ${#other_pkgs[@]}))"
if [[ $num_changed_pkgs -gt 0 ]]; then
	if [[ -v removed_pkgs ]]; then
		echo
	fi
	echo "$num_changed_pkgs version changes:"
	printf '  %s\n' "${environment_pkgs[@]}" "${other_pkgs[@]}"
fi
