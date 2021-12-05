# Update
	This is obsolete, because:
	1. LXD now provides openwrt images.
	2. LXC distrobuilder can be used to create openwrt images.
	See [distrobuilder](https://github.com/lxc/distrobuilder) [lxc-ci](https://github.com/lxc/lxc-ci)

These scripts create LXD images for OpenWRT.
They download generic-rootfs.tar.gz from openwrt.org, modify it slightly, and add LXD metadata.

The resulting images have a couple of problems:
- In order to complete booting, you need to run a script after starting the container, which creates missing devices in /dev
- The image should be launched in privileged mode, otherwise it can't create the missing devices.
- interactive ssh to the container does not work.  But non-interactive ssh does.

For a more complete image that does not have these problems, see https://github.com/mikma/lxd-openwrt

This may still be useful for platforms other than x86_64 or for quick testing.  

Naturally, you can (and should) run this script inside an LXD container.

Run as follows:

	sudo ./build.sh {version}

Run without arguments to find out the available versions:

	./build.sh

barrier_breaker is not usable.

The dhcp versions modify the network configuration so that the container gets its ip address from dhcp.  They also remove the wan interface.

If you use the original network configuration, which includes a DHCP server, other containers may start getting their ip addresses from the OpenWRT container (which may be useful, if you disable the LXD DHCP server).

rootfs tarballs are downloaded in ./cache, if they are not already there.
If you want to get fresh ones, delete the old ones first.

The resulting images are generated in ./target/{version}/image, which should be copied to the host.
There are also a couple of generated scripts:
import.sh imports the image
launch.sh <name> launches a container from the image

The openwrt container should be privileged:

	lxc launch {openwrt-image-alias} -c security.privileged=true {name}

The resulting container boots partially.  It becomes usable after running the script /root/init.sh.  You can exec init.sh using lxd exec, either directly, or through an interactive shell:

	lxc exec {container} /root/init.sh

or:

	lxc exec {container} ash
	sh init.sh


init.sh uses mknod to create a few missing devices in /dev.  The container should be privileged in order to be able to run mknod.

I haven't been able to make init.sh run automatically from inside the container.

To stop the container, run "halt" in it.  It does not seem to stop from the LXD tools.

If you try to run "halt" or "reboot" before completing the boot process, it won't work.  In order to get rid of such an unusable container, delete its rootfs from the host (/var/lib/lxd/containers/{container}/rootfs in pre-snap LXD).  You will then be able to delete the container after a host reboot.

The resulting container seems functional.
You can access the Luci Web Interface.
If you try to login to it with ssh, you get an error:

	PTY allocation request failed on channel 0
	shell request failed on channel 0

But you can use scp, rsync, and run non-interactive commands with ssh.

barrier_breaker does not boot properly into multiuser mode.  However, you can halt or reboot it.  init.sh does not fix it.  This script does not modify rootfs in this case.  It just adds metadata.
