{ pkgs, inputs, ... }:

# ─── noctalia.nix — Artık sadece donanım servisleri ──────────────────────────
# noctalia-shell kaldırıldı. Bluetooth, güç ve UPower servisleri korundu.
# Quickshell bu servisleri StatusIcons.qml içinde kullanır.

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
