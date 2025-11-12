{
  description = "Nixbook Live Session + Installer ISO with Cinnamon and Calamares";

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
          config = {
            allowUnfree = true;
            allowInsecurePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "broadcom-sta" # aka “wl”
              ];
          };
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
        nixbook = pkgs.fetchFromGitHub {
          owner = "ChocolateLoverRaj";
          repo = "nixbook";
          rev = "262a3796b9ef2420b840f65b504794826b62a369";
          hash = "sha256-Z0jlc8VImgc3L9P34j7/z1zMtfSJmRzGXQOU4Zg4jBA=";
        };
        liveInstallerModule = {
          imports = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix"
            "${nixbook}/common.nix"
            ./broadcom-sta.nix
          ];
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

          # After installation, these packages will be installed through Flatpak and not NixOS
          # But they are here to demo how Nixbook would be like after installing
          environment.systemPackages = with pkgs; [
            google-chrome
            zoom
            libreoffice
          ];
          # Copy Nixbook home files
          system.userActivationScripts = {
            copyNixbookHomeFiles = {
              text =
                let
                  config = nixbook + "/config/config";
                  guides = nixbook + "/guides";
                in
                ''
                  # Without the install 0644, the .config and Desktop dirs are read-only
                  # I think this is because they get copied form the nix store, which is read-only
                  cd ${config} && find . -type f -exec install -Dm 0644 "{}" "$HOME/.config/{}" \;
                  mkdir -p $HOME/Desktop
                  for f in "${guides}"/*; do
                    ln -s "$f" "$HOME/Desktop/$(basename "$f")"
                  done
                '';
            };
          };

          # Options that get used by system.build.vm
          virtualisation.vmVariant.virtualisation = {
            # 4 cores are recommended for Nixbook
            cores = 4;
            # 4GB memory is recommended for Nixbook
            memorySize = 4096;
            # Don't persist any data
            diskImage = null;
          };
        };
        standardConfiguration = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          modules = [
            liveInstallerModule
          ];
        };
        bundledConfiguration = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          modules = [
            liveInstallerModule
            {
              # Bundle in all possible packages we might use
              # From https://github.com/pete3n/nix-offline-iso/blob/6dd16a6e9634d61788096d3b7f2c2ca07af40a2f/flake.nix#L53-L55
              isoImage.storeContents = [
                ./default-configuration.nix
                "${nixbook}/base.nix"
                "${nixbook}/base_lite.nix"
              ];
              isoImage.includeSystemBuildDependencies = true;
            }
          ];
        };
      in
      {
        packages = {
          vm = standardConfiguration.config.system.build.vm;
          standardIso = standardConfiguration.config.system.build.isoImage;
          bundledIso = bundledConfiguration.config.system.build.isoImage;
        };
      }
    );
}
