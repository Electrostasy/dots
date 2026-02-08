{
  zramSwap.enable = true;

  # Optimize swap to better utilize zram:
  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  # https://docs.kernel.org/admin-guide/sysctl/vm.html
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };
}
