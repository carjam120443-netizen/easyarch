# EasyArch

An easy-to-use Arch-based Linux distribution.

## Current goal

EasyArch is currently in its first ISO-building stage. The project uses Arch Linux and `archiso` to produce a bootable live/install image.

### Planned defaults

- Arch Linux base
- x86_64
- KDE Plasma
- NetworkManager
- SDDM
- Calamares installer
- pacman and AUR compatibility

## Building locally

On an Arch Linux system, install `archiso` and run:

```bash
sudo pacman -S --needed archiso
./build.sh
```

The resulting ISO is placed in `out/`.

## GitHub Actions

The `Build EasyArch ISO` workflow builds the ISO in an Arch Linux container. It runs automatically when ISO-related files change and can also be started manually with **Run workflow**.

> EasyArch is experimental software. Always test generated ISOs in a virtual machine before installing on physical hardware.
