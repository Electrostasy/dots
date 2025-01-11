{ python3

, ffmpeg
, openai-whisper-cpp

, lib
}:

python3.pkgs.buildPythonApplication {
  pname = "discord-transcriber";
  version = "0.1";
  pyproject = true;

  src = ./src;

  build-system = [ python3.pkgs.setuptools ];

  dependencies = [
    (python3.pkgs.discordpy.overrideAttrs (oldAttrs: {
      version = "0-unstable-2024-12-01";
      src = oldAttrs.src.override {
        # The original derivation uses a tag, but we need a specific commit.
        tag = null;
        rev = "9806aeb83179d0d1e90d903e30db7e69e0d492e5";
        hash = "sha256-TpqtK2AuS1PE+lZh6bvrhaqowYKKj8l4cxmLDDKir4s=";
      };
    }))
  ];

  buildInputs = [
    ffmpeg
    openai-whisper-cpp
  ];

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [
      ffmpeg
      openai-whisper-cpp
    ]}"
  ];

  meta = {
    description = "Discord audio message transcriber bot";
    license = lib.licenses.gpl3;
    mainProgram = "discord-transcriber";
  };
}
