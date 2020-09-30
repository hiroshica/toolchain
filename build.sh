#!/bin/sh
set -e
if [ $# -eq 1 ]; then
    if [ $1 = "clean" ] ; then
        CLEANONLY=true
    else
        CLEANONLY=false
     fi
else
    CLEANONLY=false
fi

if [ $CLEANONLY = "true" ] ; then
  make distclean
  exit 0
fi

echo "Starting build..."
# Use the default config and patch it to point to our install location.
make rg350_defconfig
sed -ie 's%^BR2_HOST_DIR=.*$%BR2_HOST_DIR="/opt/gcw0-toolchain"%' .config
# Clear the install location.
rm -rf /opt/gcw0-toolchain /opt/rg350-toolchain
make toolchain -j7
make sdl sdl_image
#
ln -s /opt/gcw0-toolchain/ /opt/rg350-toolchain
