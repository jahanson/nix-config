{ config, pkgs, talhelper, ... }:

{
  # TODO please change the username & home direcotry to your own
  home.username = "jahanson";
  home.homeDirectory = "/home/jahanson";

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "Joseph Hanson";
    userEmail = "joe@veri.dev";
  };

  # exa replacement, ls replacement.
  programs.lsd.enable = true;
  programs.fish = {
    enable = true;
    shellAliases = {
      # lsd
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lt = "lsd --tree";
      lla = "lsd -la";

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
        body = "fastfetch";
      };
    };
  };

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them

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
    go-task
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
    kustomize

    # networking tools
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # kubernetes
    k9s
    kubectl
    kubelogin-oidc # omni login for k8s
    krew
    fluxcd
    kubernetes-helm
    cilium-cli
    hubble

    # misc
    fastfetch
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
    nixd # nix lsp server

    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal

    btop # replacement of htop/nmon
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
    rtx # rtx package manager

    # Browsers
    firefox
    vivaldi
    vivaldi-ffmpeg-codecs

    # Email
    thunderbird

    # Dev
    vscode
    termius
  ];

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

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    # custom settings
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
      window.dimensions = {
        columns = 120;
        lines = 30;
      };
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
