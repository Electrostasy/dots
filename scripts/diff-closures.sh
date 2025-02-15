#!/usr/bin/env bash
# vim: et:sw=2:ts=2:

# Since we invoke Nix multiple times, this will print the warning multiple times
# if the repo has uncommitted changes, so let's just silence it for all invocations.
function nix {
  command nix --option warn-dirty false "$@"
}

function diff_closures {
  left="$1"
  if [[ "$2" == *'#nixosConfigurations.'* ]]; then
    right="$2.config.system.build.toplevel"
  else
    right="$2"
  fi
  right="$(nix build "$right" --no-link --print-out-paths)"

  nix store diff-closures "$left" "$right" | grep '→' | grep --invert-match 'ε'
}

hostname="$(cat /proc/sys/kernel/hostname)"
if [ -z "$hostname" ]; then
  hostname='default'
fi

before_closure="${1:-/run/current-system}"
after_closure="${2:-/etc/nixos#nixosConfigurations.\"$hostname\"}"

# A list of all packages in the new system's `environment.systemPackages`.
mapfile -t _environment_pkgs < <(nix eval --raw "$after_closure" --apply 'c: c.lib.concatStringsSep "\n" (c.lib.unique (builtins.map (x: x.pname) (builtins.filter (x: x ? pname) c.config.environment.systemPackages)))')

function is_environment_pkg {
  pkg_name="$1"
  printf '%s\0' "${_environment_pkgs[@]}" | grep --fixed-strings --line-regexp --null-data --quiet -- "$pkg_name"
}

# Collect all version changes between the two closures, ignoring "abnormal"
# packages without a version number (have 'ε' or epsilon for a version).
# https://github.com/NixOS/nix/blob/master/src/nix/diff-closures.md
while read -r -a update; do
  # First token has a trailing colon we need to remove.
  pkg_name="${update[0]::-1}"

  # After the first token, delimited by a colon, is more than 1 pair of comma
  # delimited fields for versions, optionally ending in closure size. We split
  # the rest of the fields on comma into an array.
  mapfile -td ',' fields < <(echo "${update[*]:1}")

  for field in "${fields[@]}"; do
    # There is a space after the comma in each field which we trim.
    field="${field## }"
    # Colour the name green if any one of the fields indicates this
    # is a new package (begins with null set symbol).
    if [[ "$field" == '∅ →'* ]]; then
      added_pkgs+=("$(printf "\033[0;32m%s\033[0m: %s\n" "$pkg_name" "${update[*]:1}")")
      break
    fi

    # Colour the name red if any one of the fields indicates this
    # is a removed package (ends with null set symbol).
    if [[ "$field" == *'→ ∅' ]]; then
      removed_pkgs+=("$(printf "\033[0;31m%s\033[0m: %s\n" "$pkg_name" "${update[*]:1}")")
      break
    fi

    if is_environment_pkg "$pkg_name"; then
      # Packages that are part of `environment.systemPackages` are coloured
      # bright blue.
      environment_pkgs+=("$(printf "\033[0;94m%s\033[0m: %s\n" "$pkg_name" "${update[*]:1}")")
    else
      # Packages that are not part of `environment.systemPackages` are coloured
      # dark blue.
      other_pkgs+=("$(printf "\033[0;34m%s\033[0m: %s\n" "$pkg_name" "${update[*]:1}")")
    fi
  done
done < <(diff_closures "$before_closure" "$after_closure")

num_added_pkgs="${#added_pkgs[@]}"
if [ "$num_added_pkgs" -gt 0 ]; then
  echo "$num_added_pkgs added package$([ "$num_added_pkgs" -gt 1 ] && echo 's'):"
  printf '  %s\n' "${added_pkgs[@]}"
  echo
fi

num_removed_pkgs="${#removed_pkgs[@]}"
if [ "$num_removed_pkgs" -gt 0 ]; then
  echo "$num_removed_pkgs removed package$([ "$num_removed_pkgs" -gt 1 ] && echo 's'):"
  printf '  %s\n' "${removed_pkgs[@]}"
  echo
fi

# TODO: Why are there duplicates?
num_environment_pkgs="${#environment_pkgs[@]}"
num_other_pkgs="${#other_pkgs[@]}"
num_total_other_pkgs=$((num_environment_pkgs + num_other_pkgs))
if [ "$num_total_other_pkgs" -gt 0 ]; then
  echo "$num_total_other_pkgs version change$([ "$num_total_other_pkgs" -gt 1 ] && echo 's'):"
  if [ "$num_environment_pkgs" -gt 0 ]; then
    printf '  %s\n' "${environment_pkgs[@]}" | sort -u
  fi

  if [ "$num_other_pkgs" -gt 0 ]; then
    printf '  %s\n' "${other_pkgs[@]}" | sort -u
  fi
fi
