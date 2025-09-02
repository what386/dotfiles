awful = require("awful")
ruled = require("ruled")

ruled.client.append_rule({
	rule = { class = "org.wezfurlong.wezterm" },
	properties = { screen = 1, tag = awful.screen.focused().tags[1] },
})

ruled.client.append_rule({
	rule = { class = "zen" },
	properties = { screen = 1, tag = awful.screen.focused().tags[3] },
})

ruled.client.append_rule({
	rule = { class = "obsidian" },
	properties = { screen = 1, tag = awful.screen.focused().tags[4] },
})

ruled.client.append_rule({
	rule = { class = "vesktop" },
	properties = { screen = 1, tag = awful.screen.focused().tags[8] },
})
ruled.client.append_rule({
	rule = { class = "eu.betterbird.Betterbird" },
	properties = { screen = 1, tag = awful.screen.focused().tags[9] },
})
ruled.client.append_rule({
	rule = { class = "com.github.th_ch.youtube_music" },
	properties = { screen = 1, tag = awful.screen.focused().tags[10] },
})
