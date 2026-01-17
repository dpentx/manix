{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./greetd.nix
    ./zapret.nix
    ./modules/qemu.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Istanbul";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # XServer ve Wayland desteği
  services.xserver.enable = true;
  programs.xwayland.enable = true;

  # DBus
  services.dbus.enable = true;

  # XDG Portal
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = "gtk";
      };
    };
  };

  # PipeWire (ses için)
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
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "tr_TR.UTF-8";
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
    packages = with pkgs; [];
  };

  # Zsh'ı sistem genelinde etkinleştir
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.niri.enable = true;

  # Steam yapılandırması
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Steam için environment variables
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  # 32-bit desteği (Steam için)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    tuigreet
    niri
    kitty
    fuzzel
    dbus
    xdg-utils
    # Tema paketleri
    gnome-themes-extra
    adwaita-icon-theme
  ];

  # Polkit (yetkili işlemler için)
  security.polkit.enable = true;
  
  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

  # Font desteği
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];

  system.stateVersion = "25.11";
}
