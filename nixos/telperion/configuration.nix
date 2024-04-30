# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  sops = {
    # Mounts unencrypted sops values at /run/secrets/rndc_keys accessible by root only by default.
    secrets = {
      "bind/rndc-keys/externaldns" = {
        owner = config.users.users.named.name;
        inherit (config.users.users.named) group;
      };
      "bind/zones/jahanson.tech" = {
        owner = config.users.users.named.name;
        inherit (config.users.users.named) group;
      };
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network settings
  networking = {
    hostName = "telperion"; # Define your hostname.
    networkmanager.enable = true;
  };
  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jahanson = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    matchbox-server
  ];

  # Bind DNS server for externaldns on k8s to push zone updates
  services.bind = {
    enable = true;
    extraConfig = import ./config/bind.nix {inherit config;};
  };

  # TFTP Server for pushing the files for PXE booting
  services.tftpd = {
    enable = true;
  };

  # Matchbox Server for PXE booting via device profiles
  users.groups.matchbox = {};
  users.users = {
    matchbox = {
      home = "/srv/matchbox";
      group = "matchbox";
      isSystemUser = true;
    };
  };

  systemd.services.matchbox = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.matchbox-server}/bin/matchbox -address=0.0.0.0:8080 -data-path=/srv/matchbox -assets-path=/srv/matchbox/assets -log-level=debug";
      Restart = "on-failure";
      User = "matchbox";
      Group = "matchbox";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  system.stateVersion = "24.05"; # Did you read the comment?

}