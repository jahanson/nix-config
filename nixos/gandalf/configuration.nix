# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, inputs, config, ... }:
let
  upsPassword = "illgettoiteventually";
  vendorid = "0764";
  productid = "0501";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.nixvirt-git.nixosModules.default
    ];
  sops = {
    # Mounts unencrypted sops values at /run/secrets/rndc_keys accessible by root only by default.
    secrets = {
      "lego/dnsimple/token" = {
        mode = "0444";
      };
    };
  };

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
    hostName = "gandalf"; 
    hostId = "e2fc95cd";
    useDHCP = false; # needed for bridge
    networkmanager.enable = true;
    firewall.enable = false;
    interfaces = {
      "enp130s0f0".useDHCP = true;
      "enp130s0f1".useDHCP = true;
    };
    bridges = {
      "br0" = {
        interfaces = [ "enp130s0f1" ];
      };
    };
  };
  
  environment.systemPackages = with pkgs; [
    podman-compose
    lazydocker
  ];

  # Services

  # OpenSSH daemon.
  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
  services.prometheus.exporters.zfs.enable = true;
  services.prometheus.exporters.smartctl.enable = true;

  # UPS & NUT
  power.ups = {
    enable = true;
    ups.cyberpower = {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        "vendorid = ${vendorid}"
        "productid = ${productid}"
        "product = CP1500AVRLCDa"
        "serial = CTHKY2013373"
        "vendor = CPS"
        "bus = 002"
      ];
    };
  };
  users = {
    users.nut = {
      isSystemUser = true;
      group = "nut";
      # it does not seem to do anything with this directory
      # but something errored without it, so whatever
      home = "/var/lib/nut";
      createHome = true;
    };
    groups.nut = { };
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="${vendorid}", ATTRS{idProduct}=="${productid}", MODE="664", GROUP="nut", OWNER="nut"
  '';

  systemd.services.upsd.serviceConfig = {
    User = "root";
    Group = "nut";
  };

  systemd.services.upsdrv.serviceConfig = {
    User = "root";
    Group = "nut";
  };

  # reference: https://github.com/networkupstools/nut/tree/master/conf
  environment.etc = {
    # all this file needs to do is exist
    upsdConf = {
      text = "";
      target = "nut/upsd.conf";
      mode = "0440";
      group = "nut";
      user = "nut";
    };
    upsdUsers = {
      # update upsmonConf MONITOR to match
      text = ''
      [upsmon]
        password = ${upsPassword}
        upsmon master
      '';
      target = "nut/upsd.users";
      mode = "0440";
      group = "nut";
      user = "nut";
    };
    # RUN_AS_USER is not a default
    # the rest are from the sample
    # grep -v '#' /nix/store/8nciysgqi7kmbibd8v31jrdk93qdan3a-nut-2.7.4/etc/upsmon.conf.sample
    upsmonConf = {
      text = ''
        RUN_AS_USER nut

        MINSUPPLIES 1
        SHUTDOWNCMD "shutdown -h 0"
        POLLFREQ 5
        POLLFREQALERT 5
        HOSTSYNC 15
        DEADTIME 15
        RBWARNTIME 43200
        NOCOMMWARNTIME 300
        FINALDELAY 5
        MONITOR cyberpower@localhost 1 upsmon ${upsPassword} master
      '';
      target = "nut/upsmon.conf";
      mode = "0444";
    };
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
    containers = {
      # Unifi Controller
      unifi = {
        image = "ghcr.io/goofball222/unifi:8.1.113";
        ports = [
        "3478:3478/udp"  # STUN
        "8080:8080"      # inform controller
        "8443:8443"      # https
        "8880:8880"      # HTTP portal redirect
        "8843:8843"      # HTTPS portal redirect
        ];
        autoStart = true;
        volumes = [ 
          "/eru/containers/volumes/unifi/cert:/usr/lib/unifi/cert"
          "/eru/containers/volumes/unifi/data:/usr/lib/unifi/data"
          "/eru/containers/volumes/unifi/logs:/usr/lib/unifi/logs"
        ];
        environment = {
          TZ = "America/Chicago";
          RUNAS_UID0 = "false";
          PGID = "102";
          PUID = "999";
        };
      };
      lego-auto = {
        image = "ghcr.io/bjw-s/lego-auto:v0.3.0";
        autoStart = true;
        volumes = [ 
          "/eru/containers/volumes/unifi/cert:/certs"
        ];
        user = "999:102";
        environment = {
          TZ = "America/Chicago";
          LA_DATADIR="/certs";
          LA_CACHEDIR="/certs/.cache";
          LA_EMAIL = "joe@veri.dev";
          LA_DOMAINS = "gandalf.jahanson.tech";
          LA_PROVIDER = "dnsimple";
          DNSIMPLE_OAUTH_TOKEN_FILE = "${config.sops.secrets."lego/dnsimple/token".path}";
        };
      };
      # # Xen-orchestra container
      # xen-orchestra = {
      #   image = "docker.io/ronivay/xen-orchestra:5.140.1";
      #   ports = [ "80:80" ];
      #   volumes = [ 
      #     "/eru/containers/volumes/xo-data:/var/lib/xo-server"
      #     "/eru/containers/volumes/xo-redis-data:/var/lib/redis"
      #     "/eru/xen-backups:/backups"
      #   ];
      #   environment = {
      #     HTTP_PORT = "80";
      #   };
      #   extraOptions = [
      #     "--device=/dev/fuse:/dev/fuse"
      #     "--device=/dev/loop-control:/dev/loop-control"
      #     "--device=/dev/loop0:/dev/loop0"
      #     "--device=/dev/loop0:/dev/loop1"
      #     "--device=/dev/loop0:/dev/loop2"
      #     "--device=/dev/loop0:/dev/loop3"
      #   ];
      # };
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
      "eru/hansonhive" = {
        recursive = true;
        autoprune = true;
        autosnap = true;
        hourly =  24;
        daily =  7;
        monthly = 12;
      };
      "eru/tm_joe" = {
        recursive = true;
        autoprune = true;
        autosnap = true;
        hourly =  24;
        daily =  7;
        monthly = 12;
      };
      "eru/tm_elisia" = {
        recursive = true;
        autoprune = true;
        autosnap = true;
        hourly =  24;
        daily =  7;
        monthly = 12;
      };
      "eru/containers/volumes/xo-data" = {
        recursive = true;
        autoprune = true;
        autosnap = true;
        hourly =  24;
        daily =  7;
        monthly = 12;
      };
      "eru/containers/volumes/xo-redis-data" = {
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