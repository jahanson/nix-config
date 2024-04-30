# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, lib, ... }:

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
      "1password-credentials.json" = {
        mode = "0444";
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

  # Proxy DHCP for PXE booting. This leaves DHCP address allocation alone and dhcp clients 
  # should merge all responses from their DHCPDISCOVER request.
  # https://matchbox.psdn.io/network-setup/#proxy-dhcp
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      # Disables only the DNS port.
      port = 0;
      dhcp-range = [ "10.1.1.1,proxy,255.255.255.0" ];
      enable-tftp = true;
      tftp-root = "/srv/tftp";
      # if request comes from iPXE user class, set tag "ipxe"
      dhcp-userclass = "set:ipxe,iPXE";
      # if request comes from older PXE ROM, chainload to iPXE (via TFTP)
      # ALSO 
      # point ipxe tagged requests to the matchbox iPXE boot script (via HTTP)
      # pxe-service="tag:ipxe,0,matchbox,http://10.1.1.57:8080/boot.ipxe";
      # also this double pxe-service config hack sucks, but it works.
      pxe-service=''
      tag:#ipxe,x86PC,"PXE chainload to iPXE",undionly.kpxe
      pxe-service=tag:ipxe,0,matchbox,http://10.1.1.57:8086/boot.ipxe
      '';
      log-queries = true;
      log-dhcp = true;
    };
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
      ExecStart = "${pkgs.matchbox-server}/bin/matchbox -address=0.0.0.0:8086 -data-path=/srv/matchbox -assets-path=/srv/matchbox/assets -log-level=debug";
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

  # 1Password Connect API and Sync services
  virtualisation.podman = {
    enable = true;

    # `docker` alias for podman
    dockerCompat = true;

    # Required for podman-compose so pods can talk to each other.
    defaultNetwork.settings.dns_enabled = true;

  };

  virtualisation.oci-containers.containers = {
    onepassword-connect-api = {
      image = "docker.io/1password/connect-api:1.7.2";
      autoStart = true;
      ports = [ "8080:8080" ];
      volumes = [
        "${config.sops.secrets."1password-credentials.json".path}:/home/opuser/.op/1password-credentials.json"
        "/var/lib/onepassword-connect:/home/opuser/.op/data"
      ];
    };

    onepassword-connect-sync = {
      image = "docker.io/1password/connect-sync:1.7.2";
      autoStart = true;
      ports = [ "8081:8080" ];
      volumes = [
        "${config.sops.secrets."1password-credentials.json".path}:/home/opuser/.op/1password-credentials.json"
        "/var/lib/onepassword-connect:/home/opuser/.op/data"
      ];
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  system.stateVersion = "24.05"; # Did you read the comment?

}