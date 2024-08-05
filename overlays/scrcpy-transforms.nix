# Fork of scrcpy containing scale, position and rotation offsets clientside.

final: prev:

let
  version = "2.3.1";
  server = prev.fetchurl {
    name = "scrcpy-server";
    inherit version;
    url = "https://github.com/Genymobile/scrcpy/releases/download/v${version}/scrcpy-server-v${version}";
    hash = "sha256-9oFIIvwwinpTLyU0hckDgYPGKWpsXfRwqeODtPjnYFs=";
  };

  fix-compilation-patch = prev.writeText "find-math.patch" ''
    diff --git a/app/meson.build b/app/meson.build
    index 88e2df9aa..d6f403dbe 100644
    --- a/app/meson.build
    +++ b/app/meson.build
    @@ -99,6 +99,7 @@ endif
     cc = meson.get_compiler('c')
     
     dependencies = [
    +    cc.find_library('m'),
         dependency('libavformat', version: '>= 57.33'),
         dependency('libavcodec', version: '>= 57.37'),
         dependency('libavutil'),
  '';
in

{
  scrcpy = prev.scrcpy.overrideAttrs (oldAttrs: {
    inherit version;

    src = prev.fetchgit {
      url = "https://github.com/lucidrealitylabs/scrcpy";
      branchName = "feature/additional-transformations";
      rev = "16f93ac5fdac3439dc473f944dc5e8fea821ba7d";
      hash = "sha256-LYo9Borpv2AKKxSVarv4XnmaMDdkQEPb9i3ZZ2g7BF0=";
    };

    # Fix compilation as stated in the comment:
    # https://github.com/Genymobile/scrcpy/pull/4658#issuecomment-1935895430
    patches = oldAttrs.patches or [] ++ [ fix-compilation-patch ];
    postPatch = ''
      sed -i 's/float32_t/float/g' app/src/screen.c
    '';

    # The `scrcpy-server` binary has to match versions with the client, but
    # since we override the newer scrcpy, and this fork is older, we need to
    # install the matching, older server.
    postInstall = oldAttrs.postInstall or "" + ''
      unlink "$out/share/scrcpy/scrcpy-server"
      ln -s "${server}" "$out/share/scrcpy/scrcpy-server"
    '';
  });
}
