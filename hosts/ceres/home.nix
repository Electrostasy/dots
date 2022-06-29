{ pkgs, ... }:

{
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    du-dust
    fio
    libewf
    virt-manager
  ];

  programs = {
    bottom = {
      enable = true;

      settings.flags.tree = true;
    };

    tealdeer = {
      enable = true;

      settings = {
        display = {
          use_pager = false;
          compact = false;
        };

        updates = {
          auto_update = true;
          auto_update_interval_hours = 720;
        };
      };
    };

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
  };
}
