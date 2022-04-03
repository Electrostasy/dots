{ config, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.greetd.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --greeting "Access is restricted to authorized users only." \
        --remember \
        --cmd ${ pkgs.writeShellScript "tuigreet-cmd.sh" ''
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=sway
          export XDG_CURRENT_DESKTOP=sway

          export MOZ_ENABLE_WAYLAND=1
          export CLUTTER_BACKEND=wayland
          export QT_QPA_PLATFORM=wayland-egl
          export ECORE_EVAS_ENGINE=wayland-egl
          export ELM_ENGINE=wayland_egl
          export SDL_VIDEODRIVER=wayland
          export _JAVA_AWT_WM_NONREPARENTING=1
          export NO_AT_BRIDGE=1

          exec ${pkgs.dbus}/bin/dbus-run-session -- wayfire
        '' }
    '';
  };
}
