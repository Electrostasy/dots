final: prev: {
  qemu = prev.qemu.overrideAttrs (oldAttrs: {
    # qemu-x86_64 doesn't support unshare on aarch64-linux (CLONE_NEWUSER):
    # https://gitlab.com/qemu-project/qemu/-/issues/871, and this questionable
    # patch (hack) enables generating images using the `image.repart` NixOS
    # module for aarch64-linux on x86_64-linux through binfmt.
    patches = oldAttrs.patches or [] ++ [ ./0001-fix-unshare-on-qemu.patch ];
  });
}
