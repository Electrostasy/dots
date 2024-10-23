#!/usr/bin/env -S nix env shell nixpkgs#nix-update --command bash

(cd "$(git rev-parse --show-toplevel)" && nix-update --flake --version=branch "legacyPackages.$(nix eval --raw --impure --expr 'builtins.currentSystem').vimPlugins.hlargs-nvim")
