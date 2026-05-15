return {
	network_interface = {
		-- Wired interface
		wired = "enp0s31f6",
		-- Wireless interface
		wireless = "wlan0",

	},

	vpn_interface = {
		name = "happycloud",
		conf = "/etc/wireguard/happycloud.conf"
	},
}
