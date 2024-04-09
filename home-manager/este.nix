{
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

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
