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
    
    # GL wrapper for nix-built graphical apps on non-NixOS hosts (Manjaro)
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The shell as a flake: its Home Manager module installs the runtime tools (matugen, qrencode, ...)
    # and writes ~/.config/quickshell. Used by the Manjaro host (see modules/niri/qs-niri-hm.nix).
    qs-niri = {
      url = "github:dpentx/qs-niri/oneui8-adapt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qs-theme = {
     url = "github:dpentx/qs-niri";
     flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, quickshell, ... }@inputs: {
    # Manjaro (or any non-NixOS distro) with Nix + standalone home-manager:
    #   home-manager switch --flake .#manjaro
    homeConfigurations.manjaro = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./home/manjaro.nix ];
    };

    nixosConfigurations.asus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./nixos/hardware-configuration.nix
        ./nixos/configuration.nix
        ./modules/config/hardware-conf.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.asus = {
            imports = [ ./home/home.nix ];
          };
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
