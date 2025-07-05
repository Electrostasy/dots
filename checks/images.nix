{ self, ... }:

# These derivations are not normally checked if they evaluate, so they must be
# specified as checks.

{
  aarch64-linux = {
    atlas-image = self.outputs.nixosConfigurations.atlas.config.system.build.images.default;
    deimos-image = self.outputs.nixosConfigurations.deimos.config.system.build.images.default;
    hyperion-image = self.outputs.nixosConfigurations.hyperion.config.system.build.images.default;
    luna-image = self.outputs.nixosConfigurations.luna.config.system.build.images.default;
    mars-image = self.outputs.nixosConfigurations.mars.config.system.build.images.default;
    phobos-image = self.outputs.nixosConfigurations.phobos.config.system.build.images.default;
  };
}
