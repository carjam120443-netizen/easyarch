#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/profile"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"
BUILD_PROFILE="$WORK_DIR/profile"

command -v mkarchiso >/dev/null 2>&1 || {
  echo "Error: mkarchiso is not installed. Install the archiso package first."
  exit 1
}

rm -rf "$WORK_DIR"
mkdir -p "$BUILD_PROFILE" "$OUT_DIR"

# Start from Arch's maintained releng profile so bootloader and live-media
# configuration stays compatible with current archiso releases.
cp -a /usr/share/archiso/configs/releng/. "$BUILD_PROFILE/"

cp "$PROFILE_DIR/profiledef.sh" "$BUILD_PROFILE/profiledef.sh"
cp "$PROFILE_DIR/packages.x86_64" "$BUILD_PROFILE/packages.x86_64"

if [[ -d "$PROFILE_DIR/airootfs" ]]; then
  cp -a "$PROFILE_DIR/airootfs/." "$BUILD_PROFILE/airootfs/"
fi

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
