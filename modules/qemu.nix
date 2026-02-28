{ config, pkgs, ... }:

{
  # Gerekli paketler
  environment.systemPackages = with pkgs; [
    qemu_kvm
    virt-manager
    virt-viewer           
    libvirt               
    bridge-utils          
    spice                 
    spice-gtk             
    spice-protocol        
  ];

  # Virtualization servisleri
  virtualisation.libvirtd = {
    enable = true;
    
    # QEMU ayarları
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      verbatimConfig = ''
        security_driver = "none"
        user = "asus"
        group = "asus"
      '';
    };
    
    onBoot = "ignore";
    onShutdown = "shutdown"; 
  };

  # KVM kernel modülü
  boot.kernelModules = [ "kvm-intel" ];
  
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
