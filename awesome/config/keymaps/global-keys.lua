-- Required libraries
local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup")
local apps = require("config.user.preferences")

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()

-- Modkey: Mod4 (Super key) or Mod1 (Alt key)
local modkey = "Mod4"

-- AwesomeWM
local keys = gears.table.join(

	awful.key({ modkey }, "F1", function()
		awesome.emit_signal("panel::musicplayer:show")
	end, { description = "show the music player", group = "panes" }),

	awful.key({ modkey }, "F2", function()
		local focused = awful.screen.focused()
		focused.dashboard:toggle()
	end, { description = "toggle dashboard ", group = "panes" }),

	awful.key({ modkey }, "F3", function()
		local focused = awful.screen.focused()
		focused.infopanel:toggle()
	end, { description = "toggle infopanel", group = "panes" }),

	awful.key({ modkey }, "F4", function()
		awesome.emit_signal("panel::dock:show")
	end, { description = "show the dock", group = "panes" }),

	awful.key({ modkey }, "r", function()
		awesome.emit_signal("flyout::promptbox:activate")
	end, { description = "show run dialogue", group = "flyouts" }),

	awful.key({ modkey }, "s", function()
		awesome.emit_signal("flyout::promptbox:activate")
	end, { description = "show signal dialogue", group = "flyouts" }),

	awful.key({ modkey }, "Return", function()
		awesome.emit_signal("flyout::quake_terminal:toggle")
	end, { description = "show terminal", group = "flyouts" }),

	awful.key({ modkey }, "l", function()
		awesome.emit_signal("flyout::quake_scratchpad:toggle")
	end, { description = "show scratchpad", group = "flyouts" }),

	awful.key({ modkey }, "k", function()
		awesome.emit_signal("flyout::osd_keyboard:toggle")
	end, { description = "show keyboard", group = "flyouts" }),

	--awesome

	awful.key({ modkey }, "Escape", function()
		awesome.emit_signal("screen::exit_screen:show")
	end, { description = "show exit menu", group = "awesome" }),

	awful.key(
		{ modkey, "Control" },
		"h",
		hotkeys_popup.show_help,
		{ description = "show help menu", group = "awesome" }
	),
	awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
	awful.key({ modkey, "Control" }, "q", function()
		awesome.quit()
	end, { description = "force quit", group = "awesome" }),

	-- Launcher

	awful.key({ modkey }, "o", function()
		awful.spawn(apps.default.rofi_appmenu)
	end, { description = "open program", group = "launcher" }),

	awful.key({ modkey }, "p", function()
		awful.spawn(apps.default.rofi_global)
		--awful.spawn("rofi -show window -show-icons")
	end, { description = "search windows", group = "launcher" }),

	awful.key({ modkey }, "Print", function()
		local home = os.getenv("HOME")
		local filepath = home .. "/Pictures/Screenshots/"
		awful.spawn.with_shell("flameshot full --path " .. filepath)
	end, { description = "full-screen screenshot", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "Print", function()
		local home = os.getenv("HOME")
		local filepath = home .. "/Pictures/Screenshots/"
		awful.spawn.with_shell("flameshot full --path " .. filepath)
	end, { description = "screenshot area (gui)", group = "launcher" }),
	awful.key({ modkey, "Control" }, "Print", function()
		local home = os.getenv("HOME")
		local filepath = home .. "/Pictures/Screenshots/"
		awful.spawn.with_shell("flameshot full --clipboard --path " .. filepath)
	end, { description = "full-screen screenshot (to clipboard)", group = "launcher" }),

	-- Screen
	awful.key({ modkey, "Control" }, "j", function()
		awful.screen.focus_relative(1)
	end, { description = "focus next screen", group = "screen" }),
	awful.key({ modkey, "Control" }, "k", function()
		awful.screen.focus_relative(-1)
	end, { description = "focus previous screen", group = "screen" }),

	-- System
	awful.key({}, "XF86AudioRaiseVolume", function()
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%", false)
		awesome.emit_signal("volume::changed:level")
		awesome.emit_signal("osd::volume_osd:show", true)
	end, { description = "raise volume", group = "device" }),

	awful.key({}, "XF86AudioLowerVolume", function()
		awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%", false)
		awesome.emit_signal("osd::volume_osd:show", true)
		awesome.emit_signal("volume::changed:level")
	end, { description = "lower volume", group = "device" }),

	awful.key({}, "XF86AudioMute", function()
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
		awesome.emit_signal("osd::volume_osd:show", true)
		awesome.emit_signal("volume::changed:muted")
	end, { description = "toggle volume", group = "device" }),

	awful.key({}, "XF86AudioMicMute", function()
		awful.spawn("amixer set Capture toggle", false)
		awesome.emit_signal("osd::microphone_osd:show", true)
	end, { description = "toggle mic", group = "device" }),

	awful.key({}, "XF86AudioPlay", function()
		awful.spawn("playerctl play-pause", false)
	end, { description = "play/pause track", group = "media" }),

	awful.key({}, "XF86AudioPause", function()
		awful.spawn("playerctl pause", false)
	end, { description = "pause track", group = "media" }),

	awful.key({}, "XF86AudioNext", function()
		awful.spawn("playerctl next", false)
	end, { description = "next track", group = "media" }),

	awful.key({}, "XF86AudioPrev", function()
		awful.spawn("playerctl previous", false)
	end, { description = "previous track", group = "media" }),

	awful.key({}, "XF86MonBrightnessUp", function()
		awful.spawn("brightnessctl s 5%+", false)
		awesome.emit_signal("osd::brightness_osd:show", true)
		awesome.emit_signal("widget::brightness")
	end, { description = "brightness up", group = "device" }),

	awful.key({}, "XF86MonBrightnessDown", function()
		awful.spawn("brightnessctl s 5%-", false)
		awesome.emit_signal("osd::brightness_osd:show", true)
		awesome.emit_signal("widget::brightness")
	end, { description = "brightness down", group = "device" }),

	-- Layout
	awful.key({ modkey }, "u", awful.client.urgent.jumpto, { description = "urgent client", group = "layout" }),
	awful.key({ modkey }, "space", function()
		awful.layout.inc(1)
	end, { description = "next layout", group = "layout" }),
	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(-1)
	end, { description = "previous layout", group = "layout" }),
	awful.key({ modkey, "Control" }, "l", function()
		awful.tag.incmwfact(0.05)
	end, { description = "increase master client", group = "layout" }),
	awful.key({ modkey, "Control" }, "h", function()
		awful.tag.incmwfact(-0.05)
	end, { description = "decrease master client", group = "layout" }),
	awful.key({
		modifiers = { modkey },
		keygroup = "numrow",
		description = "to tag",
		group = "layout",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				tag:view_only()
			end
			awesome.emit_signal("panel::dock:show")
		end,
	}),
	awful.key({
		modifiers = { modkey, "Control" },
		keygroup = "numrow",
		description = "toggle tag",
		group = "layout",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end,
	}),
	awful.key({
		modifiers = { modkey, "Shift" },
		keygroup = "numrow",
		description = "move focused client to tag",
		group = "layout",
		on_press = function(index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end,
	}),
	awful.key({
		modifiers = { modkey, "Control", "Shift" },
		keygroup = "numrow",
		description = "toggle focused client on tag",
		group = "layout",
		on_press = function(index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end,
	}),

	awful.key({
		modifiers = { modkey },
		keygroup = "numpad",
		description = "select layout directly",
		group = "layout",
		on_press = function(index)
			local t = awful.screen.focused().selected_tag
			if t then
				t.layout = t.layouts[index] or t.layout
			end
		end,
	}),
	awful.key({ modkey }, "Left", function()
		awful.tag.viewprev()
		awesome.emit_signal("panel::dock:show")
	end, { description = "view previous tag", group = "layout" }),
	awful.key({ modkey }, "Right", function()
		awful.tag.viewnext()
		awesome.emit_signal("panel::dock:show")
	end, { description = "view next tag", group = "layout" })
)

root.keys(keys)
