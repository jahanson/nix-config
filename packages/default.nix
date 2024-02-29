{
  self,
  nix-fast-build,
  ...
}:
hostPlatform:

let
  inherit (self.pkgs."x86_64-linux") callPackage lib linkFarm;

  hostDrvs =  lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel) self.nixosConfigurations;

  compatHosts = lib.filterAttrs (_: host: host.hostPlatform == hostPlatform) self.hosts;
  compatHostDrvs = lib.mapAttrs
    (name: _: hostDrvs.${name})
    compatHosts;

  compatHostsFarm = linkFarm "hosts-x86_64-linux" (lib.mapAttrsToList (name: path: { inherit name path; }) compatHostDrvs);
in
compatHostDrvs
// (lib.optionalAttrs (compatHosts != { }) {
  default = compatHostsFarm;
}) // {
  inherit (nix-fast-build.packages."x86_64-linux") nix-fast-build;
  inherit (self.pkgs."x86_64-linux") cachix nix-eval-jobs;
}