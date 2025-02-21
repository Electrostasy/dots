#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "USAGE: $0 <derivation>"
	echo "  where <derivation> can be for e.g. 'nixpkgs#hello'"
	exit 1
fi

if ! nix path-info --derivation "$1" &> /dev/null; then
	echo "ERROR: argument '$1' is not a derivation!"
	exit 1
fi

output_dir="$(mktemp --directory --suffix='is-cached')"
configfile="$output_dir/configfile"

function cursor_hide {
	echo -en '\e[?25l'
}

function cursor_show {
	echo -en '\e[?25h'
}

function println_yellow {
	printf '\033[0;33m%s\033[0m\n' "$1"
}

function println_green {
	printf '\033[0;32m%s\033[0m\n' "$1"
}

function println_red {
	printf '\033[0;31m%s\033[0m\n' "$1"
}

function sort_by_store_path {
	local -n paths_array=$1
	# sort only after the `/nix/store/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-`
	# part of the path.
	sort -k 1.44 <(printf '%s\n' "${paths_array[@]}")
}

function cleanup {
	rm -r "$output_dir"
	cursor_show
}

trap cleanup EXIT

if ! paths_json="$(nix path-info --derivation --recursive "$1" --json 2> /dev/null)"; then
	echo "ERROR: fetching store paths for derivation '$1' returned non-zero exit code!" >&2
	exit 1
fi

if ! paths_array_str="$(jq -r 'keys | .[] | @sh "[\(.)]=\(. | sub("^/nix/store/"; "") | sub("-.*"; ""))"' <<< "$paths_json")"; then
	echo "ERROR: jq returned non-zero exit code!" >&2
	exit 1
fi

# Mapping of nix store paths to their hashes.
declare -A paths="($paths_array_str)"

for drv in ${!paths[*]}; do
	hash="${paths[$drv]}"
	echo "next"
	echo "head"
	echo "url = \"https://cache.nixos.org/$hash.narinfo\""
	echo "output = \"$output_dir/$hash\""
done > "$configfile"

curl --config "$configfile" --silent &

# Prettier status output to stderr.
cursor_hide
total_paths="${#paths[@]}"
echo -n "Querying https://cache.nixos.org with $total_paths paths:     " >&2

file_counter=0
while read -r _; do
	((++file_counter))

	echo -en "\033[4D" >&2 # move cursor left 4 columns.
	printf '%3s%%' "$((file_counter*100/total_paths))" >&2 # redraw the progress.

	if [ "$file_counter" -eq "$total_paths" ] || ! kill -0 %% &> /dev/null; then
		echo >&2 # add a gap between status and results.
		break
	fi
done < <(inotifywait --monitor --recursive --event 'create' "$output_dir" 2> /dev/null)
cursor_show

wait "$(jobs -p)" # ensure the `curl` background job finishes.

for drv in ${!paths[*]}; do
	hash="${paths[$drv]}"

	# Handle the rare cache miss, probably cloudfront magic at play but
	# cannot reproduce consistently.
	response_file="$output_dir/$hash"
	if grep -xqF 'x-cache: MISS' "$response_file"; then
		missing+=("$drv")
		continue
	fi

	if [ "$(head -n 1 "$response_file" | cut -d ' ' -f 2)" -ne 200 ]; then
		uncached+=("$drv")
	else
		cached+=("$drv")
	fi
done

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
