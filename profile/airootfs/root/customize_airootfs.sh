#!/usr/bin/env bash
set -euo pipefail

# Build and install AUR packages into the live EasyArch environment.
# AUR packages are community-maintained PKGBUILDs, so this intentionally
# builds them with makepkg rather than installing an opaque binary.
# Do NOT run a full system upgrade here: the ISO build already installs the
# package set, and pulling in Go plus a full upgrade wastes runner disk space.
pacman -S --noconfirm --needed git go

useradd --create-home --shell /bin/bash aurbuild
chown -R aurbuild:aurbuild /home/aurbuild

build_aur() {
  local package="$1"
  local workdir="/home/aurbuild/${package}"

  rm -rf "$workdir"
  sudo -u aurbuild git clone "https://aur.archlinux.org/${package}.git" "$workdir"
  sudo -u aurbuild bash -c "cd '$workdir' && makepkg --syncdeps --noconfirm --clean --cleanbuild"
  pacman -U --noconfirm "$workdir"/*.pkg.tar.zst
  rm -rf "$workdir"
  pacman -Scc --noconfirm || true
}

# yay provides normal AUR access after EasyArch is installed/booted.
build_aur yay

# fetchit is the EasyArch default system-information fetch tool.
build_aur fetchit

# Keep the canonical EasyArch Tux branding asset in one place.
install -d -m 755 /usr/share/easyarch/branding

userdel -r aurbuild || true
rm -rf /home/aurbuild /root/.cache/go-build /root/.cache/go-build-cache 2>/dev/null || true
