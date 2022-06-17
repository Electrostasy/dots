{
  programs.git = {
    enable = true;

    userName = "Gediminas Valys";
    userEmail = "steamykins@gmail.com";
    extraConfig = {
      # https://github.com/NixOS/nixpkgs/issues/169193#issuecomment-1103816735
      safe.directory = "/etc/nixos";
    };
  };
}
