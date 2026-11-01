# Shared helpers for OpenMANET USB OTG LAN sharing.

. /lib/functions.sh

openmanet_usb_otg_enabled() {
	local enabled

	config_load openmanet_usb_otg
	config_get_bool enabled main enabled 0
	[ "$enabled" -eq 1 ]
}

openmanet_usb_otg_share_mode() {
	local mode

	config_load openmanet_usb_otg
	config_get mode main share_mode bridge
	echo "$mode"
}

# Ensure usb0 is listed as a br-lan bridge port in UCI (netdev need not exist yet).
openmanet_usb_otg_bridge_usb0() {
	local section ports port found=0

	for section in $(uci -q sections network device); do
		[ "$(uci -q get network."$section".name)" = "br-lan" ] || continue
		[ "$(uci -q get network."$section".type)" = "bridge" ] || continue

		ports="$(uci -q get network."$section".ports)"
		for port in $ports; do
			[ "$port" = "usb0" ] && found=1 && break
		done
		[ "$found" -eq 1 ] || uci add_list network."$section".ports='usb0'
		uci -q commit network
		return 0
	done

	return 1
}

# Dedicated usb interface + DHCP + firewall forward toward lan/wan.
openmanet_usb_otg_apply_nat() {
	local ip netmask start limit section

	config_load openmanet_usb_otg
	config_get ip main nat_ip '192.168.42.1'
	config_get netmask main nat_netmask '255.255.255.0'
	config_get start main nat_start '100'
	config_get limit main nat_limit '50'

	uci -q batch <<-EOF
		set network.usb=interface
		set network.usb.proto='static'
		set network.usb.device='usb0'
		set network.usb.ipaddr='$ip'
		set network.usb.netmask='$netmask'

		set dhcp.usb=dhcp
		set dhcp.usb.interface='usb'
		set dhcp.usb.start='$start'
		set dhcp.usb.limit='$limit'
		set dhcp.usb.leasetime='12h'

		set firewall.usb=zone
		set firewall.usb.name='usb'
		set firewall.usb.network='usb'
		set firewall.usb.input='ACCEPT'
		set firewall.usb.output='ACCEPT'
		set firewall.usb.forward='ACCEPT'

		set firewall.usb_lan=forwarding
		set firewall.usb_lan.src='usb'
		set firewall.usb_lan.dest='lan'

		set firewall.usb_wan=forwarding
		set firewall.usb_wan.src='usb'
		set firewall.usb_wan.dest='wan'
	EOF

	# Masquerade traffic leaving wan (usual OpenWrt default). Avoid forcing
	# masq on lan — that can surprise mesh/LAN topologies; hosts that need
	# return path to 192.168.42.0/24 should route via the Pi, or switch to
	# share_mode=bridge.
	for section in $(uci -q sections firewall zone); do
		[ "$(uci -q get firewall."$section".name)" = "wan" ] || continue
		uci -q set firewall."$section".masq='1'
	done

	uci -q commit network
	uci -q commit dhcp
	uci -q commit firewall
}

openmanet_usb_otg_apply_network() {
	local mode

	openmanet_usb_otg_enabled || return 0
	mode="$(openmanet_usb_otg_share_mode)"

	case "$mode" in
		nat)
			openmanet_usb_otg_apply_nat
			;;
		bridge|*)
			openmanet_usb_otg_bridge_usb0 || return 0
			;;
	esac
}
