{ pkgs, inputs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.irqbalance.enable = true;

  boot.kernel.sysctl = {
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
    "vm.swappiness" = 10; # zram varken swap'a geç gitsin
  };

  nix.settings.auto-optimise-store = true;
   nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
