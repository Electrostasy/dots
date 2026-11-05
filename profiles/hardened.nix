{
  security = {
    enableWrappers = false;

    # If setuid/capability wrappers are disabled, then we cannot log in without
    # account-utils. Ensure it is always set.
    account-utils.enable = true;
  };

  systemd.settings.Manager = {
    NoNewPrivileges = true;
  };
}
