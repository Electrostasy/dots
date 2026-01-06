{ pkgs, ... }:

{
  boot.swraid = {
    enable = true;

    mdadmConf = ''
      PROGRAM ${pkgs.replaceVars ./mdadm-notify.sh { inherit (pkgs) notify-send-all; }}
    '';
  };

  services.smartd.enable = true;

  # for disk in /dev/sd[a-d]; do sgdisk $disk -n 1:0:0 -t 1:fd00; done
  # mdadm --create /dev/md/pool --name=pool --level=10 --layout=n2 --raid-devices=4 /dev/sd[a-d]1
  fileSystems."/data/pool" = {
    device = "/dev/md/pool";
    fsType = "xfs";
    options = [ "noatime" ];
  };
}
