local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local rubato = require("dependencies.rubato")
local dpi = beautiful.xresources.apply_dpi

local infopanel = function(s)
	local function dp(value) return beautiful.xresources.apply_dpi(value, s) end
	local ui = require("ui.panels.components")(dp)
	local mail = require("ui.panels.infopanel.recent-mail")(ui)
	local notifications = require("ui.panels.infopanel.notif-center")(s)
	local pages = { notifications = notifications, emails = ui.column(ui.card("Recent email", mail)) }
	local content = ui.viewport()
	local mode = "notifications"
	local tabs = {}
	local mail_timer = gears.timer({
		timeout = 60, autostart = false,
		callback = function() mail:refresh() end,
	})
	-- Set right panel geometry
	local panel_width = dpi(290)
	local panel_x = s.geometry.x + s.geometry.width - panel_width
	local hidden_x = s.geometry.x + s.geometry.width + dpi(8)

	local panel = wibox({
		ontop = true,
		screen = s,
		visible = false,
		type = "dock",
		width = panel_width,
		height = s.geometry.height - dpi(36) + 1,
		x = panel_x,
		y = s.geometry.y + dpi(36) - 1,
		bg = beautiful.background,
		fg = beautiful.fg_normal,
	})

	panel.opened = false
	function panel:switch_pane(name)
		if not pages[name] then return end
		mode = name
		content:set_content(pages[name])
		for key, tab in pairs(tabs) do
			tab.bg = key == name and beautiful.accent or beautiful.groups_bg
		end
		mail_timer:stop()
		if name == "emails" and self.opened then
			mail:refresh()
			mail_timer:start()
		end
	end
	local switcher = wibox.layout.flex.horizontal()
	switcher.spacing = dp(8)
	for _, item in ipairs({ { "notifications", "Notifications" }, { "emails", "Emails" } }) do
		local tab = ui.button(item[2], function() panel:switch_pane(item[1]) end)
		tabs[item[1]] = tab
		switcher:add(tab)
	end
	panel:switch_pane(mode)
	panel.opacity = 0
	panel.x = hidden_x
	local animation_token = 0

	local slide_anim = rubato.timed({
		rate = 60,
		intro = 0.08,
		outro = 0.12,
		duration = 0.22,
		easing = rubato.easing.quadratic,
		clamp_position = true,
		subscribed = function(pos)
			panel.x = pos
		end,
	})

	local fade_anim = rubato.timed({
		rate = 60,
		intro = 0.06,
		outro = 0.1,
		duration = 0.16,
		easing = rubato.easing.linear,
		clamp_position = true,
		subscribed = function(opacity)
			panel.opacity = opacity
		end,
	})

	s.backdrop_rdb = wibox({
		ontop = true,
		screen = s,
		bg = beautiful.transparent,
		type = "utility",
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
	})

	panel:struts({
		right = 0,
	})

	local open_panel = function()
		animation_token = animation_token + 1
		panel.opened = true
		panel:switch_pane(mode)

		s.backdrop_rdb.visible = true
		panel.visible = true
		panel.x = hidden_x
		panel.opacity = 0
		slide_anim.target = panel_x
		fade_anim.target = 1

		panel:emit_signal("opened")
	end

	local close_panel = function()
		animation_token = animation_token + 1
		panel.opened = false
		mail_timer:stop()
		local token = animation_token

		slide_anim.target = hidden_x
		fade_anim.target = 0
		gears.timer({
			timeout = 0.24,
			autostart = true,
			single_shot = true,
			callback = function()
				if token == animation_token then
					panel.visible = false
					s.backdrop_rdb.visible = false
				end
			end,
		})

		panel:emit_signal("closed")
	end

	-- Hide this panel when app dashboard is called.
	function panel:hide_dashboard()
		close_panel()
	end

	function panel:toggle()
		self.opened = not self.opened
		if self.opened then
			open_panel()
		else
			close_panel()
		end
	end

	s.backdrop_rdb:buttons({awful.button({}, 1, function()
		panel:toggle()
	end)})

	panel:setup({
		{
			layout = wibox.layout.align.vertical,
			{ switcher, bottom = dp(16), widget = wibox.container.margin },
			content,
			nil,
		},
		margins = dpi(16),
		widget = wibox.container.margin,
	})

	return panel
end

return infopanel
