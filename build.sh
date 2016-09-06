#!/bin/sh
# Copyright (C) 2016 Alex Athanasopoulos

# Exit on error and treat unset variables as an error.
set -eu

if [ $# = 0 ]
then
	echo "usage: sudo sh $0 <version>"
	echo "available versions:"
	echo
	ls -1 ./conf
	exit 1
fi

VERSION="$1"

if [ `id -u` != 0 ]
then
	echo need to run as root
	exit 1
fi

readonly CONFIG_DIR=./conf/$VERSION
readonly CACHE_DIR=./cache/$VERSION
readonly BUILD_DIR=./target/$VERSION
readonly IMAGE_DIR=${BUILD_DIR}/image

if [ ! -d $CONFIG_DIR ]
then
	echo directory not found: $CONFIG_DIR
	exit 1
fi

. $CONFIG_DIR/params

download_rootfs()
{
  mkdir -p $CACHE_DIR
  if [ ! -s "$CACHE_DIR/$ROOTFS" ]
  then
    echo downloading $DOWNLOAD_URL/$ROOTFS
    wget -O "$CACHE_DIR/$ROOTFS" "$DOWNLOAD_URL/$ROOTFS"
    if [ ! -s "$CACHE_DIR/$ROOTFS" ]
    then
      echo could not get $ROOTFS
      exit 1
    fi
  fi
}

update_rootfs()
{
  rm -rf $BUILD_DIR/rootfs
  rm -rf $IMAGE_DIR
  mkdir -p $IMAGE_DIR
  if [ -s "$CACHE_DIR/$ROOTFS" ]
  then
		if [ -x $CONFIG_DIR/update-rootfs.sh ]
		then
			# modify rootfs
			mkdir -p $BUILD_DIR/rootfs
			tar xf $CACHE_DIR/$ROOTFS -C $BUILD_DIR/rootfs
			$CONFIG_DIR/update-rootfs.sh $CONFIG_DIR $BUILD_DIR/rootfs
			tar cfz $IMAGE_DIR/rootfs.tar.gz -C $BUILD_DIR/rootfs ./
		else
			# copy original rootfs
			cp $CACHE_DIR/$ROOTFS $IMAGE_DIR/rootfs.tar.gz
		fi
  fi
}

readonly TIMESTAMP=`date +%s`
readonly DATETIME=`date +%Y%m%d_%H:%M`
readonly ALIAS=openwrt-${VERSION}-`date +%Y%m%d-%H%M%S`

create_image()
{
  cat $CONFIG_DIR/metadata.yaml.tpl | \
    sed "s/@TIMESTAMP@/$TIMESTAMP/g" | \
    sed "s/@DATETIME@/$DATETIME/g" > $BUILD_DIR/metadata.yaml

  tar cfz $IMAGE_DIR/metadata.tar.gz -C $BUILD_DIR metadata.yaml
  cat $BUILD_DIR/metadata.yaml

	cat <<-END > $IMAGE_DIR/README
	VERSION=$VERSION
	DATETIME=$DATETIME
	ALIAS=$ALIAS
	
	# to import this image:
	lxc image import metadata.tar.gz rootfs.tar.gz --alias=$ALIAS
	or:
	sh import.sh

	# to launch a container from the imported image:
	lxc launch $ALIAS -c security.privileged=true <name>
	or:
	sh launch.sh <name>
END
	cat <<-END >$IMAGE_DIR/import.sh
	#!/bin/sh
	lxc image import metadata.tar.gz rootfs.tar.gz --alias=$ALIAS
END
	cat <<-END >$IMAGE_DIR/launch.sh
	#!/bin/sh
	lxc launch $ALIAS -c security.privileged=true \$1
END
	echo ls -l $IMAGE_DIR
	ls -l $IMAGE_DIR
}

download_rootfs
update_rootfs
create_image
