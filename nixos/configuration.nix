{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../modules/system/loginm/greetd.nix
    ../modules/system/network/zapret.nix
    ../modules/vm/qemu.nix
    ../modules/system/nvidia.nix
    ../modules/config/steam.nix
  ];

  boot.loader.limine = {
   enable = true;
    style.wallpapers = [
    (pkgs.fetchurl {
      url = "https://w.wallhaven.cc/full/p2/wallhaven-p2rmoe.jpg";
      sha256 = "0s1linzp7y3faa9m5zbmzidhibqpv8xmbjp9sbify2qh2w4zkrva";
     })
   ];

   extraConfig = ''
    /Manjaro Linux
        protocol: efi_chainload
        image_path: boot():/EFI/Manjaro/grubx64.efi
  '';

  };
  
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [ "elevator=bfq" "pcie_aspm=off" ];
  
  networking.hostName = "niiha";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Istanbul";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
 
  hardware.graphics.enable = true;

  boot.initrd.systemd.enable = true;
  services.earlyoom.enable = true;
  services.thermald.enable = true;
  nix.settings.max-jobs = "auto";
  nix.settings.cores = 0;
 
 zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
   };

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

  console.keyMap = "trq";

  nix.settings.trusted-users = [ "root" "asus" ];  
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

  security.pam.services.hyprlock = {};

  services.gvfs.enable = true;

  services.fstrim.enable = true;

  environment.systemPackages = with pkgs; [
    tuigreet
    niri
    kitty
    git
    gitFull
    dbus
    xdg-utils
    gnome-themes-extra
    adwaita-icon-theme
    xwayland-satellite
    wirelesstools
    playerctl
    pamixer
    awww
    tmux
    curl
    grim
    slurp
    brightnessctl
    python3Packages.pywal
    wlogout
    gh
    ffmpeg

    (pkgs.runCommand "gpu-screen-recorder-wrapped" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder $out/bin/gpu-screen-recorder \
        --prefix LD_LIBRARY_PATH : ${pkgs.libglvnd}/lib \
        --prefix LD_LIBRARY_PATH : ${config.boot.kernelPackages.nvidia_x11}/lib
    '')
  ];

  environment.sessionVariables = {
  PATH = [ "${pkgs.gitFull}/libexec/git-core" ];
  };

  security.polkit.enable = true;

  security.wrappers.gsr-kms-server = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
  };

  services.gnome.gnome-keyring.enable = true;

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
