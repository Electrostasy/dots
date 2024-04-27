{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    impermanence.url = "github:nix-community/impermanence/master";
  };

  outputs = { self, nixpkgs, ... }: let
    inherit (nixpkgs) lib;

    forAllSystems = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];

    /* Attribute set of all the packages packaged in this flake, a mapping of
       package names to their paths.
    */
    pkgs = lib.packagesFromDirectoryRecursive {
      callPackage = path: overrides: path;
      directory = ./pkgs;
    };
  in {
    overlays = {
      /* Generate an overlay from `pkgs` by handling the `callPackage` behaviour
         ourselves, making exceptions for namespaced package sets. We cannot reuse
         the definitions from `self.legacyPackages.${prev.system}`, as that would
         evaluate nixpkgs twice here (prev.system does not exist then).
      */
      default = final: prev:
        lib.mapAttrs
          (name: value:
            if lib.isAttrs value then
              if lib.hasAttrByPath [ name "overrideScope'" ] prev then
                # Namespaced package sets created with `lib.makeScope pkgs.newScope`.
                prev.${name}.overrideScope (final': prev':
                  lib.mapAttrs (name': value': final'.callPackage value' { }) value)
              else if lib.hasAttrByPath [ name "extend" ] prev then
                # Namespaced package sets created with `lib.makeExtensible`.
                prev.${name}.extend (final': prev':
                  lib.mapAttrs (name': value': final.callPackage value' { }) value)
              else
                # Namespaced package sets in regular attrsets.
                prev.${name} // value
            else
              final.callPackage value { })
          pkgs;

      ewfmount-fix = final: prev: {
        libewf = prev.libewf.overrideAttrs (oldAttrs: {
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
          buildInputs = oldAttrs.buildInputs ++ [ prev.fuse ];
        });
      };

      ffmpeg-with-zmqsend = final: prev: {
        ffmpeg_7-zmqsend = (prev.ffmpeg_7.override { withZmq = true; buildAvfilter = true; }).overrideAttrs (oldAttrs: {
          # Apparently, ffmpeg compiled with libzmq support does not build the
          # zmqsend tool.
          buildFlags = oldAttrs.buildFlags ++ [ "tools/zmqsend" ];
          postInstall = ''
            install -D tools/zmqsend -t $bin/bin
          '';
        });
      };

      unl0kr_3 = final: prev: {
        unl0kr = prev.unl0kr.overrideAttrs (finalAttrs: oldAttrs: {
          # Contains various fixes since 2.0.0.
          version = "3.0.0";
          src = oldAttrs.src.override {
            owner = "postmarketOS";
            repo = "buffybox";
            rev = finalAttrs.version;
            hash = "sha256-xmyh5F6sqD1sOPdocWJtucj4Y8yqbaHfF+a/XOcMk74=";
          };
          sourceRoot = "${finalAttrs.src.name}/unl0kr";
        });
      };

      qemu-repart-image-fix = final: prev: {
        qemu-unshare = prev.qemu.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [
            # qemu-x86_64 doesn't support unshare on aarch64-linux (CLONE_NEWUSER):
            # https://gitlab.com/qemu-project/qemu/-/issues/871
            # This questionable hack allows generating images using the `image.repart`
            # NixOS module for aarch64-linux on x86_64-linux with binfmt.
            (prev.writeText "qemu-871.patch" ''
              diff --git a/util/rcu.c b/util/rcu.c
              index e587bcc..9af18e3 100644
              --- a/util/rcu.c
              +++ b/util/rcu.c
              @@ -409,12 +409,6 @@ static void rcu_init_complete(void)

                   qemu_event_init(&rcu_call_ready_event, false);

              -    /* The caller is assumed to have iothread lock, so the call_rcu thread
              -     * must have been quiescent even after forking, just recreate it.
              -     */
              -    qemu_thread_create(&thread, "call_rcu", call_rcu_thread,
              -                       NULL, QEMU_THREAD_DETACHED);
              -
                   rcu_register_thread();
               }
            '')
          ];
        });
      };

      # Add support for FBX, OFF, DAE, DXF, X, 3MF files.
      f3d-with-assimp = final: prev: {
        f3d = prev.f3d.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ prev.assimp ];

          cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
            "-DF3D_PLUGIN_BUILD_ASSIMP=ON"
          ];
        });
      };

      # Add support for STEP, IGES files.
      f3d-with-occt = final: prev: {
        f3d = prev.f3d.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ (with prev; [
            opencascade-occt
            fontconfig
          ]);

          cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
            "-DF3D_PLUGIN_BUILD_OCCT=ON"
          ];
        });
      };
    };

    /* If I instead apply overlays on nixpkgs to generate this, namespaced package
       sets will bring in all of the packages under the namespace, therefore this
       method is much cleaner.
    */
    legacyPackages =
      forAllSystems (system:
        lib.mapAttrsRecursive
          (name: value: nixpkgs.legacyPackages.${system}.callPackage value { })
          pkgs);

    packages =
      forAllSystems (system: {
        lunaImage = self.nixosConfigurations.luna.config.system.build.sdImage;
        marsImage = self.nixosConfigurations.mars.config.system.build.sdImage;
        phobosImage = self.nixosConfigurations.phobos.config.system.build.sdImage;
      });

    nixosConfigurations =
      let
        hosts =
          lib.filterAttrs
            (_: value: value == "directory")
            (builtins.readDir ./hosts);
      in
        lib.mapAttrs
          (name: _:
            lib.nixosSystem {
              # Inject this flake into the module system.
              specialArgs = { inherit self; };

              modules = [
                # Set the hostname here instead of repeating it for each host.
                { networking.hostName = name; }

                # Load the config for the host.
                ./hosts/${name}
              ];
            })
          hosts;

    nixosModules = {
      neovim = import ./modules/system/neovim;

      unl0kr-settings = import ./modules/system/unl0kr-settings;
    };

    homeManagerModules.wayfire = import ./modules/user/wayfire;
  };
}
