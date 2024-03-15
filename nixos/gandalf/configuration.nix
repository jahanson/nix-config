# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

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
    kernelParams = [ "zfs.zfs_arc_max=107374182400" ]; # 100GB
    zfs.extraPools = [ "eru" ];
  };

  # ZFS NFS Share settings for read/write. Allows root passthrough with no user permission squash. Multiple IPs.
  # sudo zfs set sharenfs="rw=10.1.2.0/24:10.5.0.8/32,no_root_squash,sec=sys,anonuid=548,anongid=548" eru/xen-backups
  # Read Only
  # sudo zfs set sharenfs="ro=10.1.2.0/24,no_root_squash,sec=sys,anonuid=548,anongid=548" eru/borg
  # Read Only and Read Write
  # sudo zfs set sharenfs="ro=10.1.2.0/24,rw=10.1.1.55/32,no_root_squash,sec=sys,anonuid=548,anongid=548" eru/borg/nextcloud
  # Disables NFS share for dataset.
  # sudo zfs set sharenfs inherit eru/xen-backups

  # Network settings
  networking = {
    hostName = "gandalf"; # Define your hostname.
    hostId = "e2fc95cd";
    networkmanager.enable = true;
    firewall.enable = false;
  };
  
  environment.systemPackages = with pkgs; [
    podman-compose
    lazydocker
    inputs.nixvirt-git.packages.${pkgs.system}.default
  ];

  # Services

  # OpenSSH daemon.
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
      hansonhive = {
        path = "/eru/hansonhive";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "www-data";
        "force group" = "www-data";
      };
      tm_joe = {
        path = "/eru/tm_joe";
        "valid users" = "jahanson";
        public = "no";
        writeable = "yes";
        "guest ok" = "no";
        "force user" = "jahanson";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
      tm_elisia = {
        path = "/eru/tm_elisia";
        "valid users" = "emhanson";
        public = "no";
        writeable = "yes";
        "guest ok" = "no";
        "force user" = "emhanson";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
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

  # Podman Containers
  virtualisation.oci-containers = {
    backend = "podman";
    containers ={
      # Xen-orchestra container
      xen-orchestra = {
        image = "docker.io/ronivay/xen-orchestra:5.136.0";
        ports = [ "80:80" ];
        volumes = [ 
          "/eru/containers/volumes/xo-data:/var/lib/xo-server"
          "/eru/containers/volumes/xo-redis-data:/var/lib/redis"
          "/eru/xen-backups:/backups"
        ];
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

  # Enable QEMU/KVM/libvirt
  virtualisation.libvirt.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      ovmf.packages = [pkgs.OVMFFull.fd];
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}
