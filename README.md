These scripts create LXD images for OpenWRT.
Naturally, you can run them inside an LXD container.  I use a privileged Ubuntu 16.04 container, so I can run things like mknod (it is not needed yet).

Run as follows:

	sudo ./build.sh {version}

Run without arguments to find out the available versions:

	sudo ./build.sh

barrier_breaker is not usable.

The dhcp versions modify the network configuration so that the container gets its ip address from dhcp.  They also remove the wan interface.  You can experiment with other network configurations.

If you use the original network configuration, which includes a DHCP server, other containers may start getting their ip addresses from the OpenWRT container (which may be useful, if you disable the LXD DHCP server).


Ths script downloads rootfs tar.gz from openwrt.org, modifies it slightly, and generates LXD metadata.

rootfs tarballs are downloaded in ./cache, if they are not already there.
If you want to get fresh ones, delete the old ones first.

The resulting images are generated in ./target/{version}/image

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

If you try to run "halt" or "reboot" before completing the boot process, it won't work.  In order to get rid of such an unusable container, delete its rootfs from the host (/var/lib/lxd/containers/{container}/rootfs).  You will then be able to delete the container after a host reboot.

The resulting container seems functional.
You can access the Luci Web Interface.
If you try to login to it with ssh, you get an error:

	PTY allocation request failed on channel 0
	shell request failed on channel 0

But you can use scp, rsync, and run non-interactive commands with ssh.

barrier_breaker does not boot properly into multiuser mode.  However, you can halt or reboot it.  init.sh does not fix it.  This script does not modify rootfs in this case.  It just adds metadata.
