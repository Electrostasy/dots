{
  programs = {
    lsd = {
      enable = true;

      settings = {
        classic = false;
        blocks = [ "permission" "user" "group" "size" "date" "name" ];
        sorting = {
          column = "name";
          dir-grouping = "first";
        };
        indicators = true;
        icons.theme = "fancy";
      };
    };

    fish.shellAliases.ls = "lsd";
    bash.shellAliases.ls = "lsd";
    zsh.shellAliases.ls = "lsd";
  };
}
