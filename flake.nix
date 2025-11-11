{
  description = "Custom NixOS Installer ISO with Calamares";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
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
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
            ./common.nix
            {
              nix.extraOptions = "experimental-features = nix-command flakes";
              isoImage.isoName = "nixos-custom-installer.iso";
              system.stateVersion = "25.05";

              # Adapted from installation-cd-graphical-calamares-gnome.nix
              isoImage.edition = "nixbook";
              services.xserver.desktopManager.cinnamon.extraGSettingsOverrides = ''
                [org.cinnamon.desktop.session]
                idle-delay=0

                [org.cinnamon.settings-daemon.plugins.power]
                sleep-inactive-ac-type='nothing'
                sleep-inactive-battery-type='nothing'
              '';

              services.displayManager.autoLogin = {
                enable = true;
                user = "nixos";
              };

              # Bundle in all possible packages we might use
              # From https://github.com/pete3n/nix-offline-iso/blob/6dd16a6e9634d61788096d3b7f2c2ca07af40a2f/flake.nix#L53-L55
              isoImage.storeContents = [
                ./base.nix
                ./base_lite.nix
              ];
              isoImage.includeSystemBuildDependencies = true;
              # This didn't work for some reason
              # isoImage.contents = [
              #   {
              #     source = builtins.fetchTarball {
              #       url = "file:///home/rajas/Documents/nixbook-installer/FLATPAKS.tar";
              #       sha256 = "sha256:1r157w17lm9mr37gy5r8siygx85pjpx0x0b9p7cniscyxx0705ga";
              #     };
              #     target = "FLATPAKS";
              #   }
              # ];
            }
          ];
        };
      in
      {
        packages.install-iso = nixosConfiguration.config.system.build.isoImage;
      }
    );
}
