#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "USAGE: $0 <derivation>"
	echo "  where <derivation> can be for e.g. 'nixpkgs#hello'"
	exit 1
fi

function cursor_hide {
	echo -en '\x1B[?25l'
}

function cursor_show {
	echo -en '\x1B[?25h'
}

function println_yellow {
	printf '\x1B[0;33m%s\x1B[0m\n' "$1"
}

function println_green {
	printf '\x1B[0;32m%s\x1B[0m\n' "$1"
}

function println_red {
	printf '\x1B[0;31m%s\x1B[0m\n' "$1"
}

function sort_by_store_path {
	local -n array=$1
	# sort only after the `/nix/store/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-`
	# part of the path.
	sort -k 1.44 <(printf '%s\n' "${array[@]}")
}

configfile="$(mktemp --suffix='is-cached-config')"

function cleanup {
	rm "$configfile"
	cursor_show
}

trap cleanup EXIT

declare -A paths
for path in $(nix path-info --derivation --recursive "$1"); do
	hash="${path:11:32}"
	paths["$hash"]="$path"

	echo 'next'
	echo 'head'
	echo 'no-show-headers'
	echo 'write-out = "%{url.path} %{response_code}\\n"'
	echo "url = \"https://cache.nixos.org/$hash.narinfo\""
done > "$configfile"

total_paths="${#paths[@]}"
echo -n "Querying https://cache.nixos.org with $total_paths paths:   0%" >&2

cursor_hide
count=0
while read -r url_path response_code; do
	path="${paths["${url_path:1:32}"]}"

	case "$response_code" in
		200) cached+=("$path") ;;
		404) uncached+=("$path") ;;
		*) missing+=("$path") ;;
	esac

	((++count))

	echo -en "\x1B[4D" >&2 # move cursor to the left by 4 cells.
	printf '%4s' "$((count*100/total_paths))%" >&2
done < <(curl --config "$configfile" --parallel --parallel-immediate --silent)
echo >&2
cursor_show

if [ -v missing ]; then
	echo
	echo "${#missing[@]} cache misses:"

	while read -r missing_drv; do
		println_red "$missing_drv"
	done < <(sort_by_store_path missing)
fi

if [ -v uncached ]; then
	echo
	echo "${#uncached[@]} uncached paths:"

	while read -r uncached_drv; do
		println_yellow "$uncached_drv"
	done < <(sort_by_store_path uncached)
fi

if [ -v cached ]; then
	echo
	echo "${#cached[@]} cached paths:"

	while read -r cached_drv; do
		println_green "$cached_drv"
	done < <(sort_by_store_path cached)
fi
