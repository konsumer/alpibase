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

dir=$(cd "${0%[/\\]*}" > /dev/null && pwd)
"${dir}/alpibase/scripts/build.sh"
source "${dir}/alpibase/scripts/qcow_handling.sh"

# mount the qcow image
mount_qimage "${ROOTFS_DIR}"

# do things in a chroot
chroot "${ROOTFS_DIR}" sh

# unmount the image
umount_qimage "${ROOTFS_DIR}"

make_bootable_image "${WORK_DIR}/${CURRENT_IMAGE}" "${WORK_DIR}/${NAME}.img"
```
