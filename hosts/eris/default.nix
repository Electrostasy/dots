{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/system/common
    ../../profiles/system/neovim
    ../../profiles/system/shell
  ];

  system.stateVersion = "22.05";

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl = {
    enable = true;
    defaultUser = "nixos";
    startMenuLaunchers = false;

    # OpenGL/CUDA from Windows instead.
    useWindowsDriver = true;

    wslConf = {
      automount.root = "/mnt";
      network = {
        hostname = config.networking.hostName;
        generateHosts = false;

        # Otherwise breaks tailscale.
        generateResolvConf = false;
      };
    };
  };

  networking.nameservers = [ "9.9.9.9" ];

  environment.systemPackages = with pkgs; [
    bintools-unwrapped
    binwalk
    dos2unix
    evtx # evtx-dump
    exiftool
    ffmpeg
    hashcat
    imagemagick
    john
    libewf
    sleuthkit # mmls, fls, fsstat, icat
    stegseek
    testdisk # photorec
    unixtools.xxd
    xlsx2csv
    xsv
  ];

  users.users.${config.wsl.defaultUser} = {
    extraGroups = [ "wheel" ];
    uid = 1000;
    openssh.authorizedKeys.keyFiles = [
      ../terra/ssh_host_ed25519_key.pub
      ../venus/ssh_host_ed25519_key.pub
    ];
  };
}
