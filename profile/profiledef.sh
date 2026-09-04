#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="easyarch"
iso_label="EASYARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="EasyArch"
iso_application="EasyArch Live/Install Media"
iso_version="0.1"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
pacman_conf="pacman.conf"
arch="x86_64"

# Keep the live root filesystem compact. XZ with the x86 BCJ filter is the
# same general compression approach used by Arch's releng profile: smaller
# images at the cost of some extra compression time, with no runtime penalty.
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')

declare -A file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/etc/sudoers.d"]="0:0:750"
)
