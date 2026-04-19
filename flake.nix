{
  description = "MaOS";

  nixConfig = {
    extra-substituters = [ "https://dpentx.cachix.org" ];
    extra-trusted-public-keys = [
      "dpentx.cachix.org-1:LUimyvpOmN+reXprnlaRof/pkA+RXVgFxf1UgKXsm1M="
    ];
  };

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
    
    qs-theme = {
     url = "github:dpentx/qs-niri";
     flake = false;
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
            imports = [ ./home.nix ];
          };
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
