final: prev:

let
  # qemu-x86_64 doesn't support unshare on aarch64-linux (CLONE_NEWUSER):
  # https://gitlab.com/qemu-project/qemu/-/issues/871, and this questionable
  # patch (hack) at least enables generating images using the `image.repart`
  # NixOS module for aarch64-linux on x86_64-linux through binfmt.
  qemu871Patch = prev.writeText "qemu-871.patch" ''
    diff --git a/util/rcu.c b/util/rcu.c
    index e587bcc..9af18e3 100644
    --- a/util/rcu.c
    +++ b/util/rcu.c
    @@ -409,12 +409,6 @@ static void rcu_init_complete(void)

         qemu_event_init(&rcu_call_ready_event, false);

    -    /* The caller is assumed to have iothread lock, so the call_rcu thread
    -     * must have been quiescent even after forking, just recreate it.
    -     */
    -    qemu_thread_create(&thread, "call_rcu", call_rcu_thread,
    -                       NULL, QEMU_THREAD_DETACHED);
    -
         rcu_register_thread();
     }
  '';
in
{
  qemu-unshare = prev.qemu.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [ qemu871Patch ];
  });
}
