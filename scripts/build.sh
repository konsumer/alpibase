#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "Please run as root" 1>&2
    exit 1
fi

# this is the name of the image
export STAGE=${NAME:-alpibase}

# this is the main working-dir (where images go)
export WORK_DIR=${WORK_DIR:-$(realpath out)} 

# this is where the root-filessystem ius built
export ROOTFS_DIR=${ROOTFS_DIR:-"${WORK_DIR}/root"} 

# the size of the qcow image
export BASE_QCOW2_SIZE=${BASE_QCOW2_SIZE:-12G}

export ALPINE_MIRROR=${ALPINE_MIRROR:-"http://dl-cdn.alpinelinux.org/alpine"}
export APK_VERSION="2.12.5-r0"

dir=$(cd "${0%[/\\]*}" > /dev/null && pwd)

source "${dir}/qcow_handling.sh"

echo -e "\e[30;42m Building image-${STAGE}.qcow2 \e[0m"
load_qimage

echo -e "\e[30;42m Setting up alpine \e[0m"

wget "${ALPINE_MIRROR}/latest-stable/main/$(uname -m)/apk-tools-static-${APK_VERSION}.apk" -O "${WORK_DIR}/apk-tools-static.tgz"
pushd > /dev/null
mkdir -p "${WORK_DIR}/apk"
cd "${WORK_DIR}/apk"
tar -xzf "${WORK_DIR}/apk-tools-static.tgz"
popd > /dev/null

"${WORK_DIR}/apk/sbin/apk.static" --arch armhf -X "${ALPINE_MIRROR}/latest-stable/main" -U --allow-untrusted -p "${ROOTFS_DIR}" --initdb add alpine-base

mknod -m 666 "${ROOTFS_DIR}/dev/full" c 1 7
mknod -m 666 "${ROOTFS_DIR}/dev/ptmx" c 5 2
mknod -m 644 "${ROOTFS_DIR}/dev/random" c 1 8
mknod -m 644 "${ROOTFS_DIR}/dev/urandom" c 1 9
mknod -m 666 "${ROOTFS_DIR}/dev/zero" c 1 5
mknod -m 666 "${ROOTFS_DIR}/dev/tty" c 5 0

mkdir -p "${ROOTFS_DIR}/etc/apk"
echo "${ALPINE_MIRROR}/latest-stable/main" > "${ROOTFS_DIR}/etc/apk/repositories"

cat << EOF > "${ROOTFS_DIR}/etc/resolv.conf"
nameserver 1.1.1.1
options edns0 trust-ad
search lan
EOF

echo "${STAGE}" > "${ROOTFS_DIR}/etc/hostname"
echo -e "\n127.0.0.2\t${STAGE}\t${STAGE}.localdomain\n" >> "${ROOTFS_DIR}/etc/hostname"

cat << CHROOT | chroot "${ROOTFS_DIR}" sh
rc-update add haveged boot
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit

rc-update add swclock boot
rc-update add modules boot
rc-update add sysctl boot
rc-update add hostname boot
rc-update add bootmisc boot
rc-update add syslog boot

rc-update add mount-ro shutdown
rc-update add killprocs shutdown
rc-update add savecache shutdown
CHROOT

unload_qimage
