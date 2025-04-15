final: prev: {
  # gamescope 3.16.3+ has inconsistent mouse grabbing and ignores
  # `--force-grab-cursor`, making some games completely unplayable by allowing
  # the cursor to veer off screen in fullscreen when using multiple displays.
  # The only solution is to downgrade to 3.16.1 (3.16.2 has worse performance):
  # https://github.com/ValveSoftware/gamescope/issues/1711#issue-2797308108
  gamescope_3_16_1 = prev.gamescope.overrideAttrs (finalAttrs: prevAttrs: {
    version = "3.16.1";

    src = prevAttrs.src.override {
      tag = finalAttrs.version;
      hash = "sha256-+0QGt4UADJmZok2LzvL+GBad0t4vVL4HXq27399zH3Y=";
    };
  });
}
