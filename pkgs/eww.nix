{ config, pkgs, lib, rustPlatform, inputs, ... }:

rustPlatform.buildRustPackage {
  pname = "eww";
  version = inputs.eww.shortRev;

  src = inputs.eww;

  nativeBuildInputs = with pkgs; [ pkg-config gtk3 ];
  buildInputs = with pkgs; [ glib ];

  cargoBuildFlags = [ "--no-default-features" "--features wayland" ];
  cargoLock.lockFile = builtins.toPath "${inputs.eww.outPath}/Cargo.lock";
}

