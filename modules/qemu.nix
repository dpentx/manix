{ config, pkgs, ... }:

{
  # QEMU/KVM sanal makine kurulumu
  # Intel i5-8250U için optimize edilmiş
  
  # Gerekli paketler
  environment.systemPackages = with pkgs; [
    qemu_kvm              # QEMU with KVM support
    virt-manager          # GUI yönetim aracı
    virt-viewer           # VM konsol görüntüleyici
    libvirt               # Virtualization API
    bridge-utils          # Network bridge araçları
    spice                 # Uzak masaüstü protokolü
    spice-gtk             # SPICE GTK widget
    spice-protocol        # SPICE protocol headers
  ];

  # Virtualization servisleri
  virtualisation.libvirtd = {
    enable = true;
    
    # QEMU ayarları
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;  # TPM emülasyonu (gerekirse)
      # OVMF UEFI desteği artık varsayılan olarak geliyor
    };
    
    # Performans optimizasyonları
    onBoot = "ignore";      # Boot'ta VM'leri otomatik başlatma
    onShutdown = "shutdown"; # Kapatırken VM'leri düzgün kapat
  };

  # KVM kernel modülü
  boot.kernelModules = [ "kvm-intel" ];  # Intel için (AMD ise "kvm-amd")
  
  # Kullanıcı izinleri - kendi kullanıcı adını buraya yaz
  users.users.asus = {
    extraGroups = [ "libvirtd" "kvm" ];
  };

  # Network bridge (opsiyonel, NAT yerine bridge kullanacaksan)
  # virtualisation.libvirtd.allowedBridges = [ "virbr0" ];

  # Firewall ayarları (VM'lerin internete çıkması için)
  networking.firewall.checkReversePath = false;

  # Dbus servisi (virt-manager için gerekli)
  services.dbus.enable = true;

  # Polkit kuralları (GUI yönetimi için)
  security.polkit.enable = true;
}
