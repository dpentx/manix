{ pkgs, inputs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  services.irqbalance.enable = true;

  boot.kernel.sysctl = {
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
    "vm.swappiness" = 10;
  };

  nix.settings.auto-optimise-store = true;
   nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
