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

# Associative array of nix store paths to their hashes.
declare -A paths="($(
	nix path-info --derivation --recursive "$1" --json 2> /dev/null | \
	jq -r 'keys | .[] | @sh "[\(.)]=\(. | sub("^/nix/store/"; "") | sub("-.*"; ""))"'
))"

output_dir="$(mktemp --directory --suffix='is-cached')"
configfile="$output_dir/configfile"

for drv in ${!paths[*]}; do
	hash="${paths[$drv]}"
	echo "next"
	echo "head"
	echo "url = \"https://cache.nixos.org/$hash.narinfo\""
	echo "output = \"$output_dir/$hash\""
done > "$configfile"

total_paths="${#paths[@]}"
echo "Querying https://cache.nixos.org with $total_paths paths..."
curl --config "$configfile" --silent &

# Because we use `curl` with a config file and multiple requests, we cannot see
# the global progress. For this reason, we run it in the background while
# calculating progress ourselves based on the number of files created compared
# to the expected total number.
file_counter=0
while read -r _; do
	((++file_counter))
	percent="$((file_counter*100/total_paths))"
	echo -en "\033[2K\r$percent%"

	# TODO: Need to test if the `kill` invocation here actually does anything useful.
	if [ "$percent" -eq 100 ] || ! kill -0 %%; then
		echo -en "\033[2K\r"
		break
	fi
done < <(inotifywait --monitor --recursive --event 'create' "$output_dir" 2> /dev/null)
wait "$(jobs -p)" # ensure the `curl` background job finishes.

for drv in ${!paths[*]}; do
	hash="${paths[$drv]}"

	# TODO: Better handling for the rare cache miss, probably cloudfront magic at play.
	response_file="$output_dir/$hash"
	if grep -xqF 'x-cache: MISS' "$response_file"; then
		missing+=("$drv")
		continue
	fi

	if [ "$(head -n 1 "$response_file" | cut -d ' ' -f 2)" -eq 200 ]; then
		cached+=("$drv")
	else
		uncached+=("$drv")
	fi
done

rm -r "$output_dir"

if [ -v uncached ]; then
	echo
	echo "${#uncached[@]} uncached paths:"

	mapfile -t uncached < <(sort -k 1.45 <(printf '%s\n' "${uncached[@]}"))
	for uncached_drv in "${uncached[@]}"; do
		printf '\033[0;33m%s\033[0m\n' "$uncached_drv"
	done
fi

if [ -v cached ]; then
	echo
	echo "${#cached[@]} cached paths:"

	mapfile -t cached < <(sort -k 1.45 <(printf '%s\n' "${cached[@]}"))
	for cached_drv in "${cached[@]}"; do
		printf '\033[0;32m%s\033[0m\n' "$cached_drv"
	done
fi

if [ -v missing ]; then
	missing_num="${#missing[@]}"
	if [ "$missing_num" -gt 0 ]; then
		echo
		echo "WARNING: $missing_num missing paths:"

		mapfile -t missing < <(sort -k 1.45 <(printf '%s\n' "${missing[@]}"))
		for missing_drv in "${missing[@]}"; do
			printf '\033[0;31m%s\033[0m\n' "$missing_drv"
		done
	fi
fi
