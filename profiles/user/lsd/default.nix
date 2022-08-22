{
  programs = {
    lsd = {
      enable = true;

      settings = {
        classic = false;
        blocks = [ "permission" "user" "group" "size" "date" "name" ];
        date = "+%Y-%m-%d %H:%M:%S %z";
        dereference = true;
        sorting = {
          column = "name";
          dir-grouping = "first";
        };
      };
    };

    fish.shellAliases.ls = "lsd";
    bash.shellAliases.ls = "lsd";
    zsh.shellAliases.ls = "lsd";
  };
}
