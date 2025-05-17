{ config, lib, ... }:

let
  cfg = config.zswap;
in

{
  options.zswap = {
    enable = lib.mkEnableOption "zswap";

    compressor = lib.mkOption {
      description = "Page compression module";
      default = "zstd";
      type = lib.types.enum [
        "842"
        "deflate"
        "lz4"
        "lz4hc"
        "lzo"
        "zstd"
      ];
    };

    zpool = lib.mkOption {
      description = "Compressed memory pool management module";
      default = "zsmalloc";
      type = lib.types.enum [
        "z3fold"
        "zbud"
        "zsmalloc"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    system.requiredKernelConfig = with config.lib.kernelConfig; [
      (isYes "ZSWAP")
      (isEnabled "ZRAM_BACKEND_${lib.toUpper cfg.compressor}")
      (isEnabled "${lib.toUpper cfg.zpool}")
    ];

    boot = {
      kernelParams = [ "zswap.enabled=1" ];

      # Required for zswap:
      # https://github.com/NixOS/nixpkgs/issues/44901
      initrd = {
        kernelModules = [
          cfg.compressor
          cfg.zpool
        ];

        systemd.tmpfiles.settings."50-zswap" = {
          "/sys/module/zswap/parameters/compressor".w.argument = cfg.compressor;
          "/sys/module/zswap/parameters/zpool".w.argument = cfg.zpool;
        };
      };
    };
  };
}
