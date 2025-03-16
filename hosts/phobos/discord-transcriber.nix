{ config, pkgs, ... }:

{
  sops.secrets.discordBotToken = {};

  systemd.services.discord-transcriber = {
    description = "Discord audio message transcriber bot";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "discord-transcriber";
      LoadCredential = "token:${config.sops.secrets.discordBotToken.path}";
    };

    path = with pkgs; [
      curl
      discord-transcriber
    ];

    preStart = ''
      if ! [ -f "$STATE_DIRECTORY/ggml-base.en.bin" ]; then
        curl -o "$STATE_DIRECTORY/ggml-base.en.bin" 'https://ggml.ggerganov.com/ggml-model-whisper-base.en.bin'
      fi
    '';

    script = ''
      discord-transcriber --model "$STATE_DIRECTORY/ggml-base.en.bin" --token "$(systemd-creds cat 'token')"
    '';
  };
}
