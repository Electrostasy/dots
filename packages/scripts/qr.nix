{ writeTextFile
, wl-clipboard
, qrencode
, zbar
, grim
, slurp
}:

writeTextFile {
  name = "qr.fish";
  text = /* fish */ ''
    #!/usr/bin/env fish
    function qr -d "Encode clipboard contents as a QR code, or decode a QR code from selected screen region"
      argparse -x e,d -x e,c 'e/encode' 'd/decode' 'c/camera' -- $argv
      if set -q _flag_encode
        # If stdin is used, encode that instead of clipboard
        set -l text
        if isatty stdin
          set text (${wl-clipboard}/bin/wl-paste)
          if test $status -ne 0
            return 1
          end
        else
          read text
        end
        echo $text | ${qrencode}/bin/qrencode -t ansiutf8
        return 0
      end
      if set -q _flag_decode
        if set -q _flag_camera
          if not test -e /dev/video0
            echo "qr: video4linux device at /dev/video0 not found!"
            return 1
          end
          ${zbar}/bin/zbarcam -Sqrcode.enable --raw --prescale=320x240 -1
          return 0
        end
        ${grim}/bin/grim -g (${slurp}/bin/slurp) - | ${zbar}/bin/zbarimg -q --raw PNG:
        return 0
      end
      echo 'Usage:'
      echo '  -e/--encode: encode one of clipboard or from stdin'
      echo '  -d/--decode: decode selected region'
      echo '  -c/--camera: decode from camera instead of region'
      return 1
    end
  '';
  executable = true;
  destination = "/share/fish/vendor_functions.d/qr.fish";
}
