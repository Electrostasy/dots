# Addresses https://github.com/NixOS/nixpkgs/issues/380079.
# Fix: https://github.com/NixOS/nixpkgs/issues/380079#issuecomment-2644791642

final: prev: {
  basedpyright = prev.basedpyright.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall + ''
      find -L $out -type l -print -delete
    '';
  });
}
