#!/bin/sh

if [ $# != 2 ]
then
	echo "usage: $0 <conf-dir> <rootfs-dir>"
	exit 1
fi

CONFIG_DIR="$1"
ROOTFS_DIR="$2"

cp $CONFIG_DIR/network $ROOTFS_DIR/etc/config/network
cp $CONFIG_DIR/init.sh $ROOTFS_DIR/root/
