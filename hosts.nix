{
  durincore = {
    type = "nixos";
    hostPlatform = "x86_64-linux";
    pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBsUe5YF5z8vGcEYtQX7AAiw2rJygGf2l7xxr8nZZa7w";
  };
  gandalf = {
    type = "nixos";
    address = "gandalf.jahanson.tech";
    hostPlatform = "x86_64-linux";
    pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBsUe5YF5z8vGcEYtQX7AAiw2rJygGf2l7xxr8nZZa7w";
    remoteBuild = true;
  };
  este = {
    type = "nixos";
    address = "este.jahanson.tech";
    hostPlatform = "x86_64-linux";
    pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBsUe5YF5z8vGcEYtQX7AAiw2rJygGf2l7xxr8nZZa7w";
    remoteBuild = true;
  };
}