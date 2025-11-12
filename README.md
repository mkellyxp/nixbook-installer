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

## Instructions for creating the ISO
Run 
```bash
nix build .#packages.x86_64-linux.iso
```
The ISO file will be in `/result/iso/`. Its size will be ~3.4 GB.

