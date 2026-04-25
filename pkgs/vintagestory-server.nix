{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  dotnet-runtime_10,
}:

let
  arm64Src = fetchurl {
    url = "https://github.com/anegostudios/VintagestoryServerArm64/releases/download/1.22.0/vs_server_linux-arm64_1.22.0.tar.gz";
    hash = "sha256-GRx/OliomkeEPnq40fsW1R8wMPemzq1jnHxIqQdnm/o=";
  };
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vintagestory-server";
  version = "1.22.0";

  src = fetchurl {
    url = "https://cdn.vintagestory.at/gamefiles/stable/vs_server_linux-x64_${finalAttrs.version}.tar.gz";
    hash = "sha256-cskh1uJLtHhYgclNcUm/OmJXpKsno3/DjWKRA1Aqxqs=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/vintagestory $out/bin
    cp -r * $out/share/vintagestory
  '' + lib.optionalString stdenvNoCC.isAarch64 ''
    rm -f $out/share/vintagestory/VintagestoryServer
    rm -f $out/share/vintagestory/VintagestoryServer.dll
    rm -f $out/share/vintagestory/VintagestoryServer.deps.json
    rm -f $out/share/vintagestory/VintagestoryServer.pdb
    rm -f $out/share/vintagestory/VintagestoryServer.runtimeconfig.json
    tar xzf ${arm64Src} -C $out/share/vintagestory
  '' + ''

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper ${lib.meta.getExe dotnet-runtime_10} $out/bin/vintagestory-server \
      --add-flags $out/share/vintagestory/VintagestoryServer.dll

    find "$out/share/vintagestory/assets/" -not -path "*/fonts/*" -regex ".*/.*[A-Z].*" | while read -r file; do
      local filename="$(basename -- "$file")"
      ln -sf "$filename" "''${file%/*}"/"''${filename,,}"
    done
  '';

  meta = {
    description = "In-development indie sandbox game about innovation and exploration (server only)";
    homepage = "https://www.vintagestory.at/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    platforms = lib.platforms.linux;
    mainProgram = "vintagestory-server";
  };
})
