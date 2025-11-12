{
  description = "Custom NixOS Installer ISO with Calamares";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs ( old: {
                patches = [
                  ./calamares-nixos-extensions/install-nixbook.patch
                  ./calamares-nixos-extensions/update-desktop-entries.patch
                  ./calamares-nixos-extensions/remove-unfree-screen.patch
                ];
              });
            })
          ];
        };

        nixosConfiguration = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"

            {
              nix.extraOptions = "experimental-features = nix-command flakes";
              isoImage.isoName = "nixos-custom-installer.iso";
              system.stateVersion = "25.05";
            }
          ];
        };
      in {
        packages.install-iso = nixosConfiguration.config.system.build.isoImage;
      });
}