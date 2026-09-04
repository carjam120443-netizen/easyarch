#!/usr/bin/env bash

iso_name="easyarch"
iso_label="EASYARCH_$(date +%Y%m)"
iso_publisher="EasyArch"
iso_application="EasyArch Live/Install Media"
iso_version="0.1"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/etc/sudoers.d"]="0:0:750"
)
