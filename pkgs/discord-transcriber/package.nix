{ python3

, ffmpeg
, whisper-cpp

, lib
}:

python3.pkgs.buildPythonApplication {
  pname = "discord-transcriber";
  version = "0.1";
  pyproject = true;

  src = ./src;

  build-system = [ python3.pkgs.setuptools ];

  dependencies = [ python3.pkgs.discordpy ];

  buildInputs = [
    ffmpeg
    whisper-cpp
  ];

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [
      ffmpeg
      whisper-cpp
    ]}"
  ];

  meta = {
    description = "Discord audio message transcriber bot";
    license = lib.licenses.gpl3;
    mainProgram = "discord-transcriber";
  };
}
