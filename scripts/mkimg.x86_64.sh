profile_x86_64() {
	profile_standard
	profile_abbrev="ext"
	title="Extended"
	desc="Most common used packages included.
		Suitable for routers and servers.
		Runs from RAM.
		Includes AMD and Intel microcode updates."
	arch="x86 x86_64"
	kernel_addons="xtables-addons zfs"
	boot_addons="amd-ucode intel-ucode"
	initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
	apks="$apks $APKS
		ethtool hwids lftp links doas
		logrotate lua5.3 lsof lm_sensors lxc lxc-templates
		pax-utils paxmark pciutils screen strace sudo tmux
		usbutils v86d vim xtables-addons curl
		acct arpon arpwatch awall bridge-utils bwm-ng
		ca-certificates conntrack-tools cutter cyrus-sasl dhcp
		dhcpcd dhcrelay dnsmasq email fping fprobe haserl htop
		igmpproxy ip6tables iproute2 iproute2-qos
		iptables iputils irssi ldns-tools links
		ncurses-terminfo net-snmp net-snmp-tools nrpe nsd
		opennhrp openvpn pingu ppp quagga
		quagga-nhrp rng-tools rpcbind sntpc socat ssmtp strongswan
		sysklogd tcpdump tinyproxy unbound
		wireless-tools wpa_supplicant zonenotify
		btrfs-progs cksfv dosfstools cryptsetup
		cciss_vol_status e2fsprogs e2fsprogs-extra efibootmgr
		grub-bios grub-efi lvm2 mdadm mkinitfs mtools nfs-utils
		parted rsync sfdisk syslinux unrar util-linux xfsprogs
		zfs
		"

	local _k _a
	for _k in $kernel_flavors; do
		apks="$apks linux-$_k"
		for _a in $kernel_addons; do
			apks="$apks $_a-$_k"
		done
	done
	apks="$apks linux-firmware"
        hostname="node"
        apkovl=$APKOVL
}
