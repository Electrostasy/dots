#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "USAGE: $0 <derivation>"
	echo "  where <derivation> can be for e.g. 'nixpkgs#hello'"
	exit 1
fi

function build_request {
	printf '%s\n' 'next' 'head' 'no-show-headers' 'write-out = "%{url.path} %{response_code}\\n"' "url = \"https://cache.nixos.org/$1.narinfo\""
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

declare -A paths
for path in $(nix path-info --derivation --recursive "$1"); do
	hash="${path:11:32}"
	paths["$hash"]="$path"
done

max_count="${#paths[@]}"
echo -n "Querying https://cache.nixos.org with $max_count paths:   0%" >&2

count=0
while read -r url_path response_code; do
	path="${paths["${url_path:1:32}"]}"

	case "$response_code" in
		200) cached+=("$path") ;;
		404) uncached+=("$path") ;;
		*) missing+=("$path") ;;
	esac

	echo -en "\x1B[4D" >&2 # move cursor to the left by 4 cells.
	printf '%4s' "$((++count * 100 / max_count))%" >&2
done < <(for hash in "${!paths[@]}"; do build_request "$hash"; done | curl -s -K - -Z --parallel-immediate)
echo >&2

if [[ -v missing ]]; then
	echo
	echo "${#missing[@]} cache misses:"
	println_red "$(sort_by_store_path missing)"
fi

if [[ -v uncached ]]; then
	if [[ -v missing ]]; then
		echo # optional spacing.
	fi
	echo "${#uncached[@]} uncached paths:"
	println_yellow "$(sort_by_store_path uncached)"
fi

if [[ -v cached ]]; then
	if [[ -v uncached ]]; then
		echo # optional spacing.
	fi
	echo "${#cached[@]} cached paths:"
	println_green "$(sort_by_store_path cached)"
fi
