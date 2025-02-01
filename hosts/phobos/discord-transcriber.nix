{ config, pkgs, lib, ... }:

{
  sops.secrets.discordBotToken = {};

  systemd.services.discord-transcriber = {
    description = "Discord audio message transcriber bot";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      StateDirectory = "discord-transcriber";

      LoadCredential = [
        "token:${config.sops.secrets.discordBotToken.path}"
      ];
    };

    preStart = ''
      pushd "$STATE_DIRECTORY"
      if ! [ -f 'ggml-base.en.bin' ]; then
        ${pkgs.whisper-cpp}/bin/whisper-cpp-download-ggml-model base.en
      fi
      popd
    '';

    script = ''
      ${lib.getExe pkgs.discord-transcriber} --model "$STATE_DIRECTORY/ggml-base.en.bin" --token "$(systemd-creds cat 'token')"
    '';
  };
}
