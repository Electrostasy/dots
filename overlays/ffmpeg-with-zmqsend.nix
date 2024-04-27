final: prev: {
  # Apparently, ffmpeg compiled with libzmq support does not build zmqsend.
  ffmpeg_7-zmqsend = (prev.ffmpeg_7.override { withZmq = true; buildAvfilter = true; }).overrideAttrs (oldAttrs: {
    buildFlags = oldAttrs.buildFlags ++ [ "tools/zmqsend" ];
    postInstall = ''
      install -D tools/zmqsend -t $bin/bin
    '';
  });
}
