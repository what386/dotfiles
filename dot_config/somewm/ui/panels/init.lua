local statusbar = require("ui.panels.statusbar")
local dashboard = require("ui.panels.dashboard")
local infopanel = require("ui.panels.infopanel")
local dock = require("ui.panels.dock")
local musicplayer = require("ui.panels.musicplayer")

screen.connect_signal("request::desktop_decoration", function(s)
	s.statusbar = statusbar(s)
	s.dashboard = dashboard(s)
	s.infopanel = infopanel(s)
	s.dockpanel = dock(s)
	s.musicplayer = musicplayer(s)
end)

screen.connect_signal("removed", function(s)
	if s.musicplayer and s.musicplayer.widget_refs then
		require("ui.panels.musicplayer.updater").unregister_widgets(s.musicplayer.widget_refs)
	end
end)
