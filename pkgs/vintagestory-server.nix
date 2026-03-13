{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  dotnet-runtime_8,
}:

let
  arm64Src = fetchurl {
    url = "https://github.com/anegostudios/VintagestoryServerArm64/releases/download/1.21.0/vs_server_linux-arm64_1.21.0.tar.gz";
    hash = "sha256-oPJrOZlBBVnx+isPPCcDZ/9Z1aKJ2ZBBnV8+MdGvWdE=";
  };
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vintagestory-server";
  version = "1.21.6";

  src = fetchurl {
    url = "https://cdn.vintagestory.at/gamefiles/stable/vs_server_linux-x64_${finalAttrs.version}.tar.gz";
    hash = "sha256-Zk1Gj44mLJVB6JBIukXohKuzm6Jlmwld3h75VxIkfqw=";
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
    makeWrapper ${lib.meta.getExe dotnet-runtime_8} $out/bin/vintagestory-server \
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
