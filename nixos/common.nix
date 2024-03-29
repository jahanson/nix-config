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
    borgbackup
    borgmatic

    #utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processer https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder
    age # sops-age encryption
    sops
    lsd

    #misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    fastfetch
    atuin
    go-task

    # archives
    zip
    xz
    unzip
    p7zip

    # terminal file managers
    nnn
    ranger
    yazi

    # networking tools
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # utils
    direnv # shell environment management
    pre-commit # Pre-commit tasks for git
    minio-client # S3 management
    shellcheck
    envsubst

  ];
  # my traceroute
  programs.mtr.enable = true;

  # starship - an customizable prompt for any shell
  programs.starship = {
    enable = true;
    # custom settings
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
      username = {
        disabled = false;
        show_always = true;
        format = "[$user]($style)@";
      };
      hostname ={ 
        disabled = false;
        ssh_only = false;
        format = "[$hostname]($style) ";
        ssh_symbol = "";
      };
    };
  };

  # Enable/Start Tailscale service
  services.tailscale.enable = true;

}
