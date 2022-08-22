{
  programs.tealdeer = {
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
}
