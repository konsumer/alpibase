# alpibase

An extremely minimal, but easy to setup, pi OS starting-point.

This is based on alpine for pi. The main goal is to make an easy-to-use starting-point and some tools to build what you need.

```sh
sudo NAME=mycoolos ./scripts/build.sh
```

If you are making your own disk-image, I recommend making this a git-submodule, then wrapping it in a script:

```sh
git submodule add https://github.com/konsumer/alpibase.git
```

Then tell your users to `git clone --recursive`.

Here is an example script:

```sh
#!/bin/bash

export NAME="mycoolos"
export WORK_DIR=$(realpath work)
export ROOTFS_DIR="${WORK_DIR}/root"

dir=$(cd "${0%[/\\]*}" > /dev/null && pwd)
"${dir}/alpibase/scripts/build.sh"
source "${dir}/alpibase/scripts/qcow_handling.sh"

# mount the qcow image
mount_qimage "${ROOTFS_DIR}"

# do things in a chroot
chroot "${ROOTFS_DIR}" sh

# unmount the image
umount_qimage "${ROOTFS_DIR}"

# generate an SD image for pi
make_bootable_image "${WORK_DIR}/${CURRENT_IMAGE}" "${WORK_DIR}/${NAME}.img"
```

## emulation

You can run it in qemu.

```
git clone --depth=1 https://github.com/dhruvvyas90/qemu-rpi-kernel
sudo NAME=mycoolos ./scripts/build.sh
sudo chown -R $(whoami) out

qemu-system-arm \
  -M versatilepb \
  -cpu arm1176 \
  -m 256 \
  -hda ./out/image-mycoolos.qcow2 \
  -net user,hostfwd=tcp::5022-:22 \
  -dtb qemu-rpi-kernel/versatile-pb-buster.dtb \
  -kernel qemu-rpi-kernel/kernel-qemu-4.19.50-buster \
  -append 'root=/dev/sda2 panic=1' \
  -no-reboot
```
