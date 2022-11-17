{ pkgs, ... }:

{
  services.pcscd.enable = true;

  home-manager.users.electro.nixpkgs.overlays = [
    # TODO: This overlay is a bit weird, overriding the package causes other
    # settings to be lost. Consider using Firefox NixOS module?
    (final: prev: {
      firefox-custom = prev.firefox-custom.override {
        extraPolicies = {
          ExtensionSettings = {
            "{27805029-2f92-4c5a-be45-ef513da27cfa}" = {
              installation_mode = "force_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/dokobit-plugin/latest.xpi";
            };
          };

          SecurityDevices = {
            # PWPW can't be loaded unless Softemia (newer ID cards) or OpenSC is
            # loaded (what).
            "OpenSC PKCS#11 Module" = "${pkgs.opensc}/lib/opensc-pkcs11.so";

            # Lithuanian national ID made before 2021-08-12
            "PWPW PKCS#11 Module" = "${pkgs.pwpw-card}/lib/pwpw-card-pkcs11.so";
          };
        };
      };
    })
  ];
  environment.systemPackages = with pkgs; [ pcsctools pwpw-card ];
  systemd.packages = [ pkgs.pwpw-card ];
}
