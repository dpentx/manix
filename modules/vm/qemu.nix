{ config, pkgs, ... }:

{
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

  virtualisation.libvirtd = {
    enable = true;
    
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

  users.users.asus = {
    extraGroups = [ "libvirtd" "kvm" ];
  };

  networking.firewall.checkReversePath = false;

  services.dbus.enable = true;

  security.polkit.enable = true;
}
