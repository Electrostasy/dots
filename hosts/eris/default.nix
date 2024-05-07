{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/common
    ../../profiles/neovim
    ../../profiles/shell
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
        generateResolvConf = false;
      };
    };
  };

  # Even if we change our WSL user to electro and specify `-u electro` to run
  # WSL as electro, we still start in /home/nixos instead of the proper directory,
  # so just copy the config symlink after creating it in the neovim profile.
  systemd.tmpfiles.settings."11-neovim"."/home/nixos/.config/nvim"."C".argument = "/home/electro/.config/nvim";

  networking.nameservers = [ "9.9.9.9" ];

  services.tailscale.enable = false;

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
