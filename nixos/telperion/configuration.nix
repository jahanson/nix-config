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
      pxe-service = [
        "tag:#ipxe,x86PC,\"PXE chainload to iPXE\",undionly.kpxe"
        "tag:ipxe,0,matchbox,http://10.1.1.57:8086/boot.ipxe"
      ];
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

  # haproxy for load balancing talos and kubernetes api.
  services.haproxy = {
    enable = true;
    config = ''
      global
        log /dev/log local0
        log /dev/log local1 notice
        daemon

      defaults
        mode http
        log global
        option httplog
        option dontlognull
        option http-server-close
        option redispatch
        retries 3
        timeout http-request 10s
        timeout queue 20s
        timeout connect 10s
        timeout client 1h
        timeout server 1h
        timeout http-keep-alive 10s
        timeout check 10s

      frontend k8s_apiserver
        bind *:6443
        mode tcp
        option tcplog
        default_backend k8s_controlplane
      
      frontend talos_apiserver                                              
        bind *:50000                                                      
        mode tcp                                                          
        option tcplog                                                     
        default_backend talos_controlplane                                

      backend k8s_controlplane
        option httpchk GET /healthz
        http-check expect status 200
        mode tcp
        option ssl-hello-chk
        balance roundrobin
        server worker1 10.1.1.61:6443 check
        server worker2 10.1.1.62:6443 check
        server worker3 10.1.1.63:6443 check

      backend talos_controlplane                                
        option httpchk GET /healthz                           
        http-check expect status 200                          
        mode tcp                                              
        option ssl-hello-chk                                  
        balance     roundrobin                                
        server worker1 10.1.1.61:50000 check  
        server worker2 10.1.1.62:50000 check
        server worker3 10.1.1.63:50000 check   
    '';
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
    defaultNetwork.settings.dns_enabled = false;

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
