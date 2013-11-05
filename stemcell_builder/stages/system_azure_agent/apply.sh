#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Replace the current repositories in image to use the azure repositories that carry the kernel and agent package that will need to upgrade the VM
sudo sed -i 's/archive.ubuntu.com/azure.archive.ubuntu.com/g' $chroot/etc/apt/sources.list
run_in_chroot $chroot "apt-add-repository 'deb http://archive.canonical.com/ubuntu precise-backports partner'"

# Install hv kernel and Azure linux agent
pkg_mgr install linux-backports-modules-hv-precise-virtual hv-kvp-daemon-init walinuxagent

# Fix GRUB timeout and boot options
sudo sed -i "s/\${GRUB_RECORDFAIL_TIMEOUT:--1}/5/ig" $chroot/etc/grub.d/00_header
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0 rootdelay=300\"/ig" $chroot/boot/grub/default
sudo sed -i "s/atapiix.disable_driver//g" $chroot/boot/grub/default

run_in_chroot $chroot 'update-grub'