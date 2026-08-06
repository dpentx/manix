{
  description = "MaOS";

  nixConfig = {
    extra-substituters = [ "https://dpentx.cachix.org" ];
    extra-trusted-public-keys = [
      "dpentx.cachix.org-1:LUimyvpOmN+reXprnlaRof/pkA+RXVgFxf1UgKXsm1M="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    niri.url = "github:sodiboo/niri-flake";
    inir.url = "github:snowarch/inir";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.asus = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./nixos/hardware-configuration.nix
        ./nixos/configuration.nix
      ];
    };
  };
}
