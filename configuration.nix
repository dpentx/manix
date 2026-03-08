{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./greetd.nix
    ./zapret.nix
    ./modules/qemu.nix
    # ✅ noctalia.nix korunuyor ama artık sadece bluetooth/power servisleri var
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_lqx;

  networking.hostName = "niiha";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Istanbul";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.xserver.enable = true;
  programs.xwayland.enable = true;

  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  i18n.defaultLocale = "tr_TR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT    = "tr_TR.UTF-8";
    LC_MONETARY       = "tr_TR.UTF-8";
    LC_NAME           = "tr_TR.UTF-8";
    LC_NUMERIC        = "tr_TR.UTF-8";
    LC_PAPER          = "tr_TR.UTF-8";
    LC_TELEPHONE      = "tr_TR.UTF-8";
    LC_TIME           = "tr_TR.UTF-8";
  };

  services.xserver.xkb = {
    layout = "tr";
    variant = "intl";
  };

  console.keyMap = "trq";

  users.users.asus = {
    isNormalUser = true;
    description = "asus";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    packages = [];
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    tuigreet
    niri
    kitty
    git                  # ← eklendi
    dbus
    xdg-utils
    gnome-themes-extra
    adwaita-icon-theme
    xwayland-satellite
    wirelesstools
    playerctl
    pamixer
    swaybg
    tmux
    curl
  ];

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    # ✅ Quickshell ikonları için nerd font (opsiyonel ama önerilir)
    nerd-fonts.jetbrains-mono
  ];

  system.stateVersion = "25.11";
}
