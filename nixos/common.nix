{ config, lib, pkgs, ... }:
{

  imports = [ ../cachix.nix ];
  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      supportedFilesystems = [ "nfs" ];
      kernelModules = [ "nfs" ];
    };
  };

  fileSystems."/mnt/borg" = {
    device = "10.1.1.13:/eru/borg";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "jahanson" ];

  # Enable fish
  programs.fish.enable = true;

  # root ssh keys
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBsUe5YF5z8vGcEYtQX7AAiw2rJygGf2l7xxr8nZZa7w"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBH3VVFenoJfnu+IFUlD79uxl7L8SFoRup33J2HGny4WEdRgGR41s0MpFKDBmxXZHy4O9Nh8NMMnpy5VhUefnIKI="
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPHFQ3hDjjrKsecn3jmSWYlRXy4IJCrepgU1HaIV5VcmB3mUFmIZ/pCZnPmIG/Gbuqf1PP2FQDmHMX5t0hTYG9A="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETR70eQJiXaJuB+qpI1z+jFOPbEZoQNRcq4VXkojWfU"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAanHn3AWxWfHv51wgDmJwhQrJgsGd+LomJJZ5kXFTP3 jahanson@durincore"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATyScd8ZRhV7uZmrQNSAbRTs9N/Dbx+Y8tGEDny30sA jahanson@Anduril"
  ];

  # Set up users
  users.users.jahanson = {
    isNormalUser = true;
    description = "Joseph Hanson";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBsUe5YF5z8vGcEYtQX7AAiw2rJygGf2l7xxr8nZZa7w"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBH3VVFenoJfnu+IFUlD79uxl7L8SFoRup33J2HGny4WEdRgGR41s0MpFKDBmxXZHy4O9Nh8NMMnpy5VhUefnIKI="
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPHFQ3hDjjrKsecn3jmSWYlRXy4IJCrepgU1HaIV5VcmB3mUFmIZ/pCZnPmIG/Gbuqf1PP2FQDmHMX5t0hTYG9A="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETR70eQJiXaJuB+qpI1z+jFOPbEZoQNRcq4VXkojWfU"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAanHn3AWxWfHv51wgDmJwhQrJgsGd+LomJJZ5kXFTP3 jahanson@durincore"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATyScd8ZRhV7uZmrQNSAbRTs9N/Dbx+Y8tGEDny30sA jahanson@Anduril"
    ];
  }; 

  # Default editor
  environment.variables.EDITOR = "vim";
  # Time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    wget
    curl
    vim
    lazygit
    tailscale
    python3
    ansible
    smartmontools
    nfs-utils
  ];

  programs.mtr.enable = true;

  # Enable/Start Tailscale service
  services.tailscale.enable = true;

}
