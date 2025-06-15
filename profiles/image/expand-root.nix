{
  systemd.repart = {
    enable = true;

    partitions."20-root".Type = "root";
  };

  boot.initrd.systemd.services.systemd-repart.unitConfig.ConditionFirstBoot = true;
}
