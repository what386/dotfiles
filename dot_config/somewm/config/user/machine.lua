return {
	network_interface = {
		-- Wired interface
		wired = "enp5s0",
		-- Wireless interface
		wireless = "wlan0",

	},

	vpn_interface = {
		name = "happycloud",
		conf = "/etc/wireguard/happycloud.conf"
	},
}
