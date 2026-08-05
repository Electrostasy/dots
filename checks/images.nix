{ self, ... }:

# `nix flake check` does not check config.system.build.images, which is why
# these additional checks are necessary.

{
  aarch64-linux = {
    atlas-image = self.outputs.nixosConfigurations.atlas.config.system.build.images.default;
    deimos-image = self.outputs.nixosConfigurations.deimos.config.system.build.images.default;
    hyperion-image = self.outputs.nixosConfigurations.hyperion.config.system.build.images.default;
    mars-image = self.outputs.nixosConfigurations.mars.config.system.build.images.default;
    pandora-image = self.outputs.nixosConfigurations.pandora.config.system.build.images.default;
    phobos-image = self.outputs.nixosConfigurations.phobos.config.system.build.images.default;
  };
}
