{
  config,
  pkgs,
  ...
}: {

  home = {
    username = "jahanson";
    homeDirectory = "/home/jahanson";
  };

    # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "Joseph Hanson";
    userEmail = "joe@veri.dev";
  };


  # exa replacement, ls replacement.
  programs.lsd.enable = true;
  
  # Fish configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      # lsd
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lt = "lsd --tree";
      lla = "lsd -la";

      # lazydocker --> lazypodman
      lazypodman="sudo DOCKER_HOST=unix:///run/podman/podman.sock lazydocker";

      # other
      df = "df -h";
      du = "du -h";
    };
      # rtx hook-env | source
      # rtx activate fish | source
    shellInit = ''
      direnv hook fish | source
      set -gx PATH $PATH $HOME/.krew/bin
    '';
    functions = {
      fish_greeting = {
        description = "Set the fish greeting";
        body = "neofetch";
      };
    };
  };

    # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them

    neofetch
    go-task
    
    # terminal file managers
    nnn
    ranger
    yazi

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processer https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder
    age # sops-age encryption
    sops 
    direnv # shell environment management
    pre-commit # Pre-commit tasks for git
    minio-client # S3 management
    shellcheck
    envsubst

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}