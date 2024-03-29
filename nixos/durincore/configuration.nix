# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, inputs,  ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Network settings
  networking = {
    hostName = "durincore"; # Define your hostname.
    networkmanager.enable = true;
  };
  
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland-git.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland-xdph-git.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # VirtManager for gandalf QEMU/KVM
  programs.virt-manager.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  
  # services.gnome.gnome-keyring.enable = true;
  # security.pam.services.jahanson.enableGnomeKeyring = true;
  # programs.seahorse.enable = true;

  # # Configure keymap in X11
  # services.xserver = {
  #   layout = "us";
  #   xkbVariant = "";
  # };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable login prompt when booting.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd Hyprland";
      };
    };
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  # Register app image as an executable and run it with appimage-run
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  systemd.user.services.ssh_agent = {
    enable = true;
    description = "OpenSSH key agent";
    documentation = ["man:ssh-agent(1)" "man:ssh-add(1)" "man:ssh(1)"];
    unitConfig = {
      ConditionEnvironment = "!SSH_AGENT_PID";
    };
    serviceConfig = {
      ExecStart = "/run/current-system/sw/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
      PassEnvironment = "SSH_AGENT_PID";
      SuccessExitStatus = "2";
      Type = "simple";
    };
    wantedBy = [ "default.target" ];
  };
}
