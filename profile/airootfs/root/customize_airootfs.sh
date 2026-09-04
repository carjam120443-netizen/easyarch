#!/usr/bin/env bash
set -euo pipefail

# Install AUR packages that were prebuilt by build.sh.
# Building them here would require a Go toolchain and large temporary build
# dependencies inside the ISO rootfs, which can exhaust the build disk.
AUR_DIR=/root/aur-packages

# Pacman can fail its filesystem space check inside the archiso chroot because
# the airootfs is not mounted as a normal filesystem during customization.
# Keep package integrity/conflict checks enabled, but disable only CheckSpace.
sed -i -E 's/^[[:space:]]*CheckSpace/#CheckSpace/' /etc/pacman.conf

if compgen -G "$AUR_DIR/*.pkg.tar.zst" >/dev/null; then
  pacman -U --noconfirm "$AUR_DIR"/*.pkg.tar.zst
fi

rm -rf "$AUR_DIR"

# Keep the canonical EasyArch Tux branding asset in one place.
install -d -m 755 /usr/share/easyarch/branding
