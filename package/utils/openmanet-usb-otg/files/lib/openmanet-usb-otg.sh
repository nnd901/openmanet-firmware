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

# Add a single port to the LAN bridge device in UCI (netdev need not exist yet).
# OpenMANET uses br-ahwlan; stock OpenWrt uses br-lan. Accept either.
openmanet_usb_otg_bridge_add_port() {
	local ifname="$1"
	local section ports port found=0 name

	[ -n "$ifname" ] || return 1

	# uci has no "sections" subcommand; list device sections via show.
	for section in $(uci -q show network | sed -n 's/^network\.\([^.]*\)=device$/\1/p'); do
		name="$(uci -q get network."$section".name)"
		case "$name" in
			br-ahwlan|br-lan) ;;
			*) continue ;;
		esac
		[ "$(uci -q get network."$section".type)" = "bridge" ] || continue

		ports="$(uci -q get network."$section".ports)"
		for port in $ports; do
			[ "$port" = "$ifname" ] && found=1 && break
		done
		[ "$found" -eq 1 ] || uci add_list network."$section".ports="$ifname"
		uci -q commit network
		return 0
	done

	return 1
}

# Bridge gadget Ethernet ports. RNDIS+ECM creates usb0 + usb1; NCM/RNDIS typically
# only usb0. Bridging both keeps WebUI reachable whichever function the host uses.
openmanet_usb_otg_bridge_gadget_ports() {
	local ok=1

	openmanet_usb_otg_bridge_add_port usb0 || ok=0
	openmanet_usb_otg_bridge_add_port usb1 || true

	[ "$ok" -eq 1 ]
}

# Back-compat alias used by older snippets / docs.
openmanet_usb_otg_bridge_usb0() {
	openmanet_usb_otg_bridge_gadget_ports
}

# Dedicated usb interface + DHCP + firewall forward toward lan/wan.
# Uses usb0 (RNDIS-only default, or RNDIS first in rndis-ecm).
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
			openmanet_usb_otg_bridge_gadget_ports || return 0
			;;
	esac
}
