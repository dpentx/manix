{
  description = "MaOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
     url = "github:nix-community/home-manager";
     inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
     url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
     inputs.nixpkgs.follows = "nixpkgs";
    };
#    caelestia-shell = {
#    url = "github:caelestia-dots/shell";
#     inputs.nixpkgs.follows = "nixpkgs";
#    };
    noctalia = {
     url = "github:noctalia-dev/noctalia-shell";
     inputs.nixpkgs.follows = "nixpkgs"; 
   };
  };

  outputs = { self, nixpkgs, home-manager, quickshell, ... }@inputs: {
    nixosConfigurations.asus = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = { inherit inputs; };
     modules = [
      ./hardware-configuration.nix
      ./configuration.nix
      ./noctalia.nix

      home-manager.nixosModules.home-manager
      {
       home-manager.useGlobalPkgs = true;
       home-manager.useUserPackages = true;
       home-manager.backupFileExtension = "backup";
       home-manager.users.asus = {
        imports = [
         ./home.nix
#         caelestia-shell.homeManagerModules.default
        ];
       };
        home-manager.extraSpecialArgs = { inherit inputs; };
     }
    ];
   };    
  };
}
