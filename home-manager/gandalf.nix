{
  pkgs,
  ...
}: {

  home = {
    username = "jahanson";
    homeDirectory = "/home/jahanson";
    stateVersion = "23.11";

    packages = with pkgs; [
      # it provides the command `nom` works just like `nix`
      # with more details log output
      nix-output-monitor
    ];
  };

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "Joseph Hanson";
    userEmail = "joe@veri.dev";
  };

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

  programs.home-manager.enable = true;
}