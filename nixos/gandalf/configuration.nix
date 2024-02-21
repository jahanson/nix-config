# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    kernelParams = [ "zfs.zfs_arc_max=107374182400" ];
    zfs.extraPools = [ "eru" ];
  };

  # sudo zfs set sharenfs="rw=10.1.2.0/24:10.5.0.8/32,no_root_squash,sec=sys,anonuid=548,anongid=548" eru/xen-backups
  # sudo zfs set sharenfs="ro=10.1.2.0/24,no_root_squash,sec=sys,anonuid=548,anongid=548" eru/borg
  # sudo zfs set sharenfs="ro=10.1.2.0/24,rw=10.1.1.55/32,no_root_squash,sec=sys,anonuid=548,anongid=548" eru/borg/nextcloud
  # sudo zfs set sharenfs inherit eru/xen-backups

  # Network settings
  networking = {
    hostName = "gandalf"; # Define your hostname.
    networkmanager.enable = true;
    hostId = "e2fc95cd";
  };
  
  environment.systemPackages = with pkgs; [
    podman-compose
    lazydocker
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # NFS
  services.nfs.server.enable = true;

  # SMB
  services.samba-wsdd = {
    # make shares visible for Windows clients
    enable = true;
    openFirewall = true;
  };
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = gandalf
      netbios name = gandalf
      security = user 
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      xen = {
        path = "/eru/xen-backups";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "apps";
        "force group" = "apps";
      };
    };
  };

  # Enable podman
  virtualisation.podman = {
    enable = true;

    # `docker` alias for podman
    dockerCompat = true;

    # Required for podman-compose so pods can talk to each other.
    defaultNetwork.settings.dns_enabled = true;

  };

  # TODO: Add xen-orchestra
  virtualisation.oci-containers = {
    backend = "podman";
    containers ={
      xen-orchestra = {
        image = "docker.io/ronivay/xen-orchestra:5.136.0";
        ports = [ "80:80" ];
        volumes = [ 
          "xen-orchestra_xo-data:/var/lib/xo-server"
          "xen-orchestra_redis-data:/var/lib/redis"
          "/eru/xen-backups:/backups"
        ];
        user = "548:548";
        environment = {
          HTTP_PORT = "80";
        };
        extraOptions = [
          "--device=/dev/fuse:/dev/fuse"
          "--device=/dev/loop-control:/dev/loop-control"
          "--device=/dev/loop0:/dev/loop0"
          "--device=/dev/loop0:/dev/loop1"
          "--device=/dev/loop0:/dev/loop2"
          "--device=/dev/loop0:/dev/loop3"
        ];
      };
    };
  };
  
  # ZFS automated snapshots
  services.sanoid = {
    enable = true;
    datasets = {
      "eru/xen-backups" = {
        recursive = true;
        autoprune = true;
        autosnap = true;
        hourly =  24;
        daily =  7;
        monthly = 12;
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}
