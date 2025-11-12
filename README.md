# Nixbook Live Session and Installer ISO Builder
This installer is very similar to the official NixOS installer which uses the Calamares installer with the GNOME or Plasma desktop environment, with the following features:
- Has the same desktop environment (Cinnamon) and preinstalled apps as Nixbook
- Automatically installs Nixbook instead of a generic NixOS installation
- Gives you the option between installing Nixbook and Nixbook Lite

## Requirements
*have flakes and nix-command enabled*

1. Clone this repo
2. cd into the folder

## Quickly testing the installer in a VM
This method is much faster than creating an ISO because it can boot the VM without creating an ISO.
```bash
nix run .#packages.x86_64-linux.vm
```

## Instructions for creating the image
There are two versions of the ISO, `standard` and `bundled`. 

### `standard`
This is similar to a NixOS installer. It has a live graphical session, but still downloads a lot of packages from the internet during installation. The output ISO size is ~3.7GB. This is ideal if you will only be installing Nixbook up to 3 times.

Run 
```bash
nix build .#packages.x86_64-linux.standardIso
```
The ISO file will be in `/result/iso/`.

### `bundled`
This includes everything in `standard`, plus it has most required Nix packages bundled in the ISO so that only a small amount (~150 MB) of data will need to be downloaded from the internet when installing Nixbook. The output ISO size is ~28GB. This is ideal if you will be installing Nixbook >3 times.

Run 
```bash
nix build .#packages.x86_64-linux.bundledIso
```
The ISO file will be in `/result/iso/`.
