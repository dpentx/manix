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
  systemd.services.dnscrypt-proxy2.serviceConfig.TimeoutStartSec = "15";
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

  # NOT: programs.swaylock diye bir NixOS SİSTEM seçeneği yok, o Home Manager'a ait
  # (home.nix'te programs.swaylock.enable ile kullanılır). hyprlock'a geçtiysen
  # onun için de aynı sebeple PAM servis dosyası gerekiyor, yoksa doğru şifreyi
  # girsen bile "invalid credentials" hatası alırsın:
  security.pam.services.hyprlock = {};

  # Nautilus'ta çöp kutusu, ağ paylaşımı bağlama ve harici disk otomatik bağlama
  # için gvfs gerekli; şu anki config'de eksikti.
  services.gvfs.enable = true;

  # SSD'lerde periyodik TRIM.
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

    # nixpkgs'teki gpu-screen-recorder paketi NVIDIA'nın NVENC/encode
    # kütüphanelerini wrapper'ına dahil etmiyor (bilinen bir NixOS
    # sorunu, bkz. wiki.nixos.org/wiki/Gpu-screen-recorder), bu yüzden
    # "vaInitialize failed" / encoder bulunamadı hatası alınıyordu.
    # LD_LIBRARY_PATH'e nvidia_x11 ve libglvnd'yi ekleyen bir wrapper
    # ile aynı isimde (gpu-screen-recorder) bir binary sağlıyoruz; bu
    # yüzden home.nix'teki home.packages listesinden düz
    # "gpu-screen-recorder" paketini KALDIRMAN gerekiyor, yoksa PATH'te
    # hangisinin öne geleceği belirsiz olur.
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

  # gpu-screen-recorder'ın KMS backend'i (gsr-kms-server) ekran içeriğini
  # yakalayabilmek için cap_sys_admin istiyor. /nix/store salt-okunur
  # olduğundan store'daki binary'ye doğrudan setcap yapılamıyor;
  # security.wrappers /run/wrappers/bin altında capability'li bir
  # kopya oluşturuyor, PATH'te store'dakinden önce geldiği için
  # gpu-screen-recorder onu buluyor.
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
