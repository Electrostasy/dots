{
  programs.git = {
    enable = true;

    config = {
      # https://github.com/NixOS/nixpkgs/issues/169193#issuecomment-1103816735
      safe.directory = "/etc/nixos";

      url = {
        "https://github.com/".insteadOf = [ "gh:" "github:" ];
        "https://gitlab.com/".insteadOf = [ "gl:" "gitlab:" ];
        "https://sr.ht/".insteadOf = [ "srht:" "sourcehut:" ];
      };

      user = {
        name = "Gediminas Valys";
        email = "steamykins@gmail.com";
      };
    };
  };
}
