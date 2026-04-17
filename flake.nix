{
  description = "MT7601U kernel driver patch for AP mode";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    let
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem linuxSystems
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
          {
            packages.default = pkgs.callPackage ./default.nix { };
          }
      ) // {
        overlays.default = final: prev: {
          mt7601u-access-pointFor = kernel:
            final.callPackage ./default.nix {
              inherit kernel;
            };
        };

        nixosModules.default = { config, lib, pkgs, ... }: {
          options.hardware.mt7601u-access-point.enable =
            lib.mkEnableOption "the MT7601U kernel module with AP mode enabled";

          config = lib.mkIf config.hardware.mt7601u-access-point.enable {
            boot.extraModulePackages = [
              (pkgs.callPackage ./default.nix {
                kernel = config.boot.kernelPackages.kernel;
              })
            ];
          };
        };

        nixosModules.mt7601u-access-point = self.nixosModules.default;
      };
}
