#!/bin/bash
set -e
umask 0022

VERSION="`cat ../version.txt`"

if [ -r "../output/images/vmlinuz.bin" ]; then
KERNEL="../output/images/vmlinuz.bin"
else
KERNEL=""
fi

if [ -r "../output/images/modules.squashfs" ]; then
MODULES_FS="../output/images/modules.squashfs"
else
MODULE_FS=""
fi

if [ -r "updatepg/mininit-syspart" ]; then
MININIT="updatepg/mininit-syspart"
else
MININIT=""
fi

if [ -r "updatepg/ubiboot-v20_mddr_512mb.bin" ]; then
BOOTLOADERS="updatepg/ubiboot-v20_mddr_512mb.bin"
else
BOOTLOADERS=""
fi

# TODO: Reinstate this:
# X-OD-Manual=CHANGELOG

# Copy kernel and rootfs to update dir.
# We want to support symlinks for the kernel and rootfs images and if no
# copy is made, specifying the symlink will include the symlink in the OPK
# and specifying the real path might use a different name than the updatepg
# script expects.
if [ "$KERNEL" ] ; then
	DATE=`date -r "$KERNEL" +%F`
else
	echo "ERROR: No kernel or rootfs found."
	exit 1
fi

if [ "$KERNEL" ] ; then

	chmod a-x "$KERNEL" "$MODULES_FS"

	echo -n "Calculating SHA1 sum of kernel... "
	sha1sum "$KERNEL" | cut -d' ' -f1 > "../output/images/vmlinuz.bin.sha1"
	echo "done"

	echo -n "Calculating SHA1 sum of modules file-system... "
	sha1sum "$MODULES_FS" | cut -d' ' -f1 > "../output/images/modules.squashfs.sha1"
	echo "done"

	KERNEL="$KERNEL ../output/images/vmlinuz.bin.sha1"
        MODULES_FS="$MODULES_FS ../output/images/modules.squashfs.sha1"
fi

if [ "$BOOTLOADERS" ] ; then

	echo -n "Calculating SHA1 sum of bootloaders... "
        sha1sum "$BOOTLOADERS" | cut -d' ' -f1 > "updatepg/ubiboot-v20_mddr_512mb.bin.sha1"
        echo "done"

        BOOTLOADERS="$BOOTLOADERS updatepg/ubiboot-v20_mddr_512mb.bin.sha1"
fi

if [ "$MININIT" ] ; then

	echo -n "Calculating SHA1 sum of mininit-syspart... "
	sha1sum "$MININIT" | cut -d' ' -f1 > "updatepg/mininit-syspart.sha1"
	echo "done"

	MININIT="$MININIT updatepg/mininit-syspart.sha1"
fi

echo "$DATE" > updatepg/date.txt

echo "$VERSION" > updatepg/version.txt

# Report metadata.
echo
echo "=========================="
echo "Bootloaders:          $BOOTLOADERS"
echo "Mininit:              $MININIT"
echo "Kernel:               $KERNEL"
echo "Modules file system:  $MODULES_FS"
echo "build date:           $DATE"
echo "build version:        $VERSION"
echo "=========================="
echo

# Write metadata.
cat > updatepg/default.gcw0.desktop <<EOF
[Desktop Entry]
Name=Kernel update $VERSION
Comment=POCKETGO2 ROGUE update $DATE
Exec=update.sh
Icon=rogue
Terminal=true
Type=Application
StartupNotify=true
Categories=applications;
EOF

# Create OPK.
OPK_FILE=updatepg/POCKETGO2-Kernel-update-$VERSION-$DATE.opk
mksquashfs \
	updatepg/default.gcw0.desktop \
	updatepg/rogue.png \
	updatepg/update.sh \
	updatepg/trimfat.py \
	updatepg/flash_partition.sh \
	updatepg/date.txt \
    updatepg/version.txt \
    updatepg/fsck.fat \
	$BOOTLOADERS \
	$MININIT \
	$KERNEL \
	$MODULES_FS \
	$OPK_FILE \
	-no-progress -noappend -comp gzip -all-root

echo
echo "=========================="
echo
echo "updater OPK:       $OPK_FILE"
echo

mv $OPK_FILE ../output/
echo
echo "=========================="
echo
echo "moved OPK to output folder"
echo

rm updatepg/default.gcw0.desktop updatepg/date.txt updatepg/version.txt updatepg/*.sha1
