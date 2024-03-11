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

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # nix-fast-build
    nix-fast-build = {
      url = "github:Mic92/nix-fast-build";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

     # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

     # deploy-rs
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # atuin
    atuin = {
      url = "github:atuinsh/atuin";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # hyprland official
    hyprland-git = {
      url = "github:hyprwm/hyprland/v0.36.0";
    };
    
    # hyprland plugin for an i3 / sway like manual tiling layout
    hy3 = {
      url = "github:outfoxxed/hy3/hl0.36.0";
    };
    
    # hyprland-xdg-portal
    hyprland-xdph-git = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
    };
    
    # hyprland-protocols
    hyprland-protocols-git.url = "github:hyprwm/hyprland-protocols";
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = { self, nixpkgs-stable, nixpkgs-unstable, home-manager-stable, home-manager-unstable, hy3, ... }@inputs:
  let
    inherit (self) outputs;
    forAllSystems = nixpkgs-stable.lib.genAttrs [
      # "aarch64-linux"
      "x86_64-linux"
    ];
  in
  {
    nixosConfigurations = {
      "durincore" = nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          # Import the configuration.nix here, so that the
          # old configuration file can still take effect.
          # Note: configuration.nix itself is also a Nixpkgs Module,
          ./nixos/durincore/configuration.nix
          ./nixos/common.nix
          # { nixpkgs.overlays = [ (self: super: { atuin = atuin.packages.${self.pkgs.system}.atuin; }) ]; }
          home-manager-unstable.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jahanson = import ./home-manager/durincore.nix;
            home-manager.extraSpecialArgs = {inherit inputs outputs;};
          }
        ];
      };
      "este" = nixpkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/este/configuration.nix
          ./nixos/common.nix
          home-manager-stable.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jahanson = import ./home-manager/este.nix;
          }
        ];
      };
      "gandalf" = nixpkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/gandalf/configuration.nix
          ./nixos/common.nix
          home-manager-stable.nixosModules.home-manager
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
