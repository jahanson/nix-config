{
  description = "NixOS Homelab";

  # This is the standard format for flake.nix.
  # `inputs` are the dependencies of the flake,
  # and `outputs` function will return all the build results of the flake.
  # Each item in `inputs` will be passed as a parameter to
  # the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs.
    # The most widely used is `github:owner/name/reference`,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-fast-build
    nix-fast-build = {
      url = "github:Mic92/nix-fast-build";
      inputs.nixpkgs.follows = "nixpkgs";
    };

     # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

     # deploy-rs
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];
  in
  {
    hosts = import ./hosts.nix;
    pkgs = forAllSystems (localSystem: import nixpkgs {
      inherit localSystem;
      config = {
        allowUnfree = true;
        allowAliases = true;
      };
    });

    packages = forAllSystems (import ./packages inputs);

    nixosConfigurations = {
      "durincore" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          # Import the configuration.nix here, so that the
          # old configuration file can still take effect.
          # Note: configuration.nix itself is also a Nixpkgs Module,
          ./nixos/durincore/configuration.nix
          ./nixos/common.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jahanson = import ./home-manager/durincore.nix;
          }
        ];
      };
      "este" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./nixos/este/configuration.nix
          ./nixos/common.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jahanson = import ./home-manager/este.nix;
          }
        ];
      };
      "gandalf" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./nixos/gandalf/configuration.nix
          ./nixos/common.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jahanson = import ./home-manager/gandalf.nix;
          }
        ];
      };
    };

  };
}
