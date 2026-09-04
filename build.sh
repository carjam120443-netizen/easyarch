#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/profile"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"
BUILD_PROFILE="$WORK_DIR/profile"
AUR_BUILD_DIR="$WORK_DIR/aur-build"
AUR_OUTPUT_DIR="$WORK_DIR/aur-packages"

command -v mkarchiso >/dev/null 2>&1 || {
  echo "Error: mkarchiso is not installed. Install the archiso package first."
  exit 1
}

# Arch's pacman disk-space check can fail inside Docker because the container's
# overlay root does not always expose a usable mount point to statvfs(). The
# GitHub runner has ample disk space, and mkarchiso performs its own build-space
# work, so disable only pacman's pre-transaction space check in this build
# container. This does not disable any package integrity or conflict checks.
sed -i -E 's/^[[:space:]]*CheckSpace/#CheckSpace/' /etc/pacman.conf

rm -rf "$WORK_DIR" "$OUT_DIR"
mkdir -p "$BUILD_PROFILE" "$OUT_DIR" "$AUR_BUILD_DIR" "$AUR_OUTPUT_DIR"

# Start from Arch's maintained releng profile so bootloader and live-media
# configuration stays compatible with current archiso releases.
cp -a /usr/share/archiso/configs/releng/. "$BUILD_PROFILE/"

cp "$PROFILE_DIR/profiledef.sh" "$BUILD_PROFILE/profiledef.sh"
cp "$PROFILE_DIR/packages.x86_64" "$BUILD_PROFILE/packages.x86_64"

# Keep the package manifests inside the live system so the EasyArch
# archinstall wrapper can use the same lists for the installed system.
install -d -m 755 "$BUILD_PROFILE/airootfs/usr/share/easyarch"
cp "$PROFILE_DIR/packages.x86_64" "$BUILD_PROFILE/airootfs/usr/share/easyarch/packages.x86_64"
if [[ -f "$PROFILE_DIR/aur-packages.txt" ]]; then
  cp "$PROFILE_DIR/aur-packages.txt" "$BUILD_PROFILE/airootfs/usr/share/easyarch/aur-packages.txt"
fi

if [[ -d "$PROFILE_DIR/airootfs" ]]; then
  cp -a "$PROFILE_DIR/airootfs/." "$BUILD_PROFILE/airootfs/"
fi

# The releng profile can contain optional PXE hooks that are unavailable in
# some archiso/mkinitcpio combinations. EasyArch is a normal bootable ISO,
# not a PXE/NFS image, so keep only the hooks needed for local ISO booting.
for mkinitcpio_conf in \
  "$BUILD_PROFILE/airootfs/etc/mkinitcpio.conf" \
  "$BUILD_PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf"; do
  if [[ -f "$mkinitcpio_conf" ]]; then
    sed -i -E 's/[[:space:]]+archiso_pxe_(common|nbd|http|nfs)//g' "$mkinitcpio_conf"
  fi
done

# Build every AUR package listed in the shared manifest outside the ISO
# rootfs. This keeps build-only dependencies out of the final image.
pacman -S --noconfirm --needed git base-devel go tomlplusplus

useradd --create-home --shell /bin/bash aurbuild
chown -R aurbuild:aurbuild "$AUR_BUILD_DIR" "$AUR_OUTPUT_DIR"

build_aur() {
  local package="$1"
  local srcdir="$AUR_BUILD_DIR/$package"

  rm -rf "$srcdir"
  runuser -u aurbuild -- git clone "https://aur.archlinux.org/${package}.git" "$srcdir"
  runuser -u aurbuild -- bash -c "cd '$srcdir' && makepkg --syncdeps --noconfirm --clean --cleanbuild"
  # Only copy the main package. Debug packages are not needed in EasyArch.
  find "$srcdir" -maxdepth 1 -type f -name "${package}-[0-9]*.pkg.tar.zst" -exec cp {} "$AUR_OUTPUT_DIR/" \;
done

while IFS= read -r package; do
  [[ -z "$package" || "$package" == \#* ]] && continue
  build_aur "$package"
done < "$PROFILE_DIR/aur-packages.txt"

rm -rf "$BUILD_PROFILE/airootfs/root/aur-packages"
mkdir -p "$BUILD_PROFILE/airootfs/root/aur-packages"
cp "$AUR_OUTPUT_DIR"/*.pkg.tar.zst "$BUILD_PROFILE/airootfs/root/aur-packages/"

# The build-only toolchain/cache is not part of the final ISO rootfs.
userdel -r aurbuild || true
rm -rf "$AUR_BUILD_DIR" "$AUR_OUTPUT_DIR" /root/.cache/go-build /root/.cache/go-build-cache
pacman -Rns --noconfirm go || true
pacman -Rns --noconfirm tomlplusplus || true
pacman -Scc --noconfirm || true

# Enable NetworkManager and SDDM in the live environment.
mkdir -p "$BUILD_PROFILE/airootfs/etc/systemd/system/multi-user.target.wants"
mkdir -p "$BUILD_PROFILE/airootfs/etc/systemd/system/graphical.target.wants"
ln -sfn /usr/lib/systemd/system/NetworkManager.service \
  "$BUILD_PROFILE/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
ln -sfn /usr/lib/systemd/system/sddm.service \
  "$BUILD_PROFILE/airootfs/etc/systemd/system/graphical.target.wants/sddm.service"

mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$BUILD_PROFILE"

echo
printf 'EasyArch ISO(s) are in: %s\n' "$OUT_DIR"
