{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.hyprland-git.homeManagerModules.default ];
  
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    plugins = [ inputs.hy3.packages.${pkgs.system}.hy3 ];
    settings = {
      "monitor" = "eDP-1,1920x1080@60,0x0,1";
      "$mainMod" = "SUPER";
      "$terminal" = "alacritty";
      "$fileManager" = "thunar";
      "$menu" = "wofi --show drun";
      bind = 
        [
          # Disables middle mouse button paste.
          ", mouse:274, exec, ;"
          # See https://wiki.hyprland.org/Configuring/Keywords/ for more

          # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod, R, exec, $menu"
          "$mainMod, P, pseudo, # dwindle"
          "$mainMod, J, togglesplit, # dwindle"

          # Move focus with mainMod + arrow keys
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Example special workspace (scratchpad)
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
        ];
      general = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";

          layout = "dwindle";
      };

      decoration = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more

          rounding = 10;

          blur = {
              enabled = true;
              size = 3;
              passes = 1;
              
              vibrancy = "0.1696";
          };

          drop_shadow = true;
          shadow_range = 4;
          shadow_render_power = 3;
          "col.shadow" = "rgba(1a1a1aee)";
      };

      animations = {
          enabled = true;

          # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation =
            [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
      };

      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # you probably want this
      };

      master = {
        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_is_master = true;
      };

      input = {
        touchpad = {
          natural_scroll = "true";
        };
      };
      windowrulev2 = "suppressevent maximize, class:.*"; # You'll probably like this.
      exec-once = 
        [
          "waybar"
          "dunst"
          "1password --silent"
        ];
    };
  };

  # please change the username & home direcotry to your own
  home.username = "jahanson";
  home.homeDirectory = "/home/jahanson";

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "Joseph Hanson";
    userEmail = "joe@veri.dev";
    extraConfig = {
      user = { signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIDSAmssproxG+KsVn2DfuteBAemHrmmAFzCtldpKl4J"; };
      gpg = { format = "ssh"; };
      "gpg \"ssh\"" = { program = "/etc/profiles/per-user/jahanson/bin/op-ssh-sign"; };
      commit = { gpgsign = true; };
    };
  };

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

      # nvd - nix visual diff
      nvdiff = "nvd diff /run/current-system result";
    };
    
    # rtx hook-env | source
    # rtx activate fish | source
    shellInit = ''
      direnv hook fish | source
      set -gx PATH $PATH $HOME/.krew/bin
    '';
    interactiveShellInit = ''
      atuin init fish | source
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

    # Hyprland must haves
    xfce.thunar # gui file manager
    wofi # Run Menu
    waybar # Wayland bar for Sway and Wlroots based compositors
    dunst # A lightweight replacement for the notification-daemons provided by most desktop environments

    # utils
    kustomize
    _1password-gui
    _1password

    # kubernetes
    k9s
    kubectl
    kubelogin-oidc # omni login for k8s
    krew
    fluxcd
    kubernetes-helm
    cilium-cli
    hubble
    lens

    # misc
    fira-code-nerdfont

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor
    # nix
    inputs.nixd-git.packages.${pkgs.system}.nixd # nix lsp server

    # productivity
    glow # markdown previewer in terminal

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

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    # custom settings
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
      window.dimensions = {
        columns = 120;
        lines = 30;
      };
    };
  };

  gtk = {
    enable = true;

    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };

    iconTheme = {
      name = "Dracula";
      package = pkgs.dracula-icon-theme;
    };

    cursorTheme = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  home.sessionVariables.GTK_THEME = "Dracula";

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
