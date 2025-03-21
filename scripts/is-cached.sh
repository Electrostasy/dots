#!/usr/bin/env bash

function print_usage {
	cat <<- EOF
	List cache availability for a derivation and its dependencies in https://cache.nixos.org.

	Usage:
	  $(basename "$0") [options] derivation

	Options:
	  -p            Query the cache in parallel
	  -h            Print this help text

	Positional arguments:
	  derivation    Derivation or flakeref#attrpath as accepted by nix path-info --derivation

	Example:
	  $(basename "$0") -p nixpkgs#hello
	EOF
}

declare -a curl_opts=()

while getopts 'ph' opt; do
	case "$opt" in
		p) curl_opts+=('-Z' '--parallel-immediate') ;;
		h) print_usage ; exit 0 ;;
		*) print_usage ; exit 1 ;;
	esac
	shift
done

if [[ $# -ne 1 ]] || ! store_paths="$(nix --experimental-features 'nix-command flakes' path-info --derivation --recursive "$1" 2> /dev/null)"; then
	print_usage
	exit 1
fi

declare -A hash_to_store_path
while read -r store_path; do
	hash_to_store_path["${store_path:11:32}"]="$store_path"
done <<< "$store_paths"

total="${#hash_to_store_path[@]}"
i=0
while read -r url_path response_code; do
	store_path="${hash_to_store_path["${url_path:1:32}"]}"
	case "$response_code" in
		200) cached+=("$store_path") ;;
		404) uncached+=("$store_path") ;;
		*)   missing+=("$store_path") ;;
	esac

	echo -en '\x1B[2K' >&2
	printf "Querying https://cache.nixos.org with %s paths: %3s%%\n" "$total" "$((++i * 100 / total))" >&2
	if [[ $i -lt $total ]]; then
		echo -en '\x1B[1F' >&2
	fi
done < <(curl "${curl_opts[@]}" -s -K <(printf '\nnext\nhead\nno-show-headers\nwrite-out = "%%{url.path} %%{response_code}\\n"\nurl = "https://cache.nixos.org/%s.narinfo"' "${!hash_to_store_path[@]}"))

if [[ -v missing ]]; then
	echo
	echo "${#missing[@]} cache misses:"
	echo -en '\x1B[;31m' >&2
	sort -k 1.44 <(printf '%s\n' "${missing[@]}")
	echo -en '\x1B[0m' >&2
fi

if [[ -v uncached ]]; then
	[[ -v missing ]] && echo
	echo "${#uncached[@]} uncached paths:"
	echo -en '\x1B[;33m' >&2
	sort -k 1.44 <(printf '%s\n' "${uncached[@]}")
	echo -en '\x1B[0m' >&2
fi

if [[ -v cached ]]; then
	[[ -v uncached ]] && echo
	echo "${#cached[@]} cached paths:"
	echo -en '\x1B[;32m' >&2
	sort -k 1.44 <(printf '%s\n' "${cached[@]}")
	echo -en '\x1B[0m' >&2
fi
