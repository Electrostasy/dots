final: prev: {
  untrunc-anthwlock = prev.untrunc-anthwlock.override {
    # Fails to build with ffmpeg 8:
    # https://github.com/anthwlock/untrunc/issues/247
    ffmpeg = prev.ffmpeg_7;
  };
}
