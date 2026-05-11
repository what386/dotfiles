local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")

local date_label = wibox.widget({
	markup = '<span font="Inter Bold 11">Agenda</span>',
	widget = wibox.widget.textbox,
})

local month_label = wibox.widget({
	markup = '<span font="Inter 9" color="#aeb7c0">Loading...</span>',
	widget = wibox.widget.textbox,
})

local calendar_box = wibox.widget({
	markup = '<span font="monospace 9">Loading calendar...</span>',
	widget = wibox.widget.textbox,
})

local refresh_icon = wibox.widget({
	markup = '<span font="Inter Bold 10">R</span>',
	align = "center",
	valign = "center",
	widget = wibox.widget.textbox,
})

local refresh_button = clickable_container(wibox.widget({
	refresh_icon,
	forced_width = dpi(24),
	forced_height = dpi(24),
	widget = wibox.container.place,
}))

local function xml_escape(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	return text
end

local function highlight_today(text)
	local day = tonumber(os.date("%d"))
	if not day then
		return text
	end
	local day_text = tostring(day)
	return text:gsub("([^%d])(" .. day_text .. ")([^%d])", "%1<span foreground='#d8e7ff' background='#4f8cff66'><b>%2</b></span>%3", 1)
end

local function refresh()
	date_label.markup = string.format('<span font="Inter Bold 11">%s</span>', os.date("%A, %B %d"))
	month_label.markup = string.format('<span font="Inter 9" color="#aeb7c0">Week %s</span>', os.date("%V"))
	awful.spawn.easy_async_with_shell("cal -m 2>/dev/null || ncal -M 2>/dev/null || date", function(stdout)
		stdout = stdout:gsub("%s+$", "")
		calendar_box.markup = string.format('<span font="monospace 9" color="#c7d0da">%s</span>', highlight_today(xml_escape(stdout)))
	end)
end

refresh_button:buttons({awful.button({}, 1, nil, refresh)})

gears.timer({ timeout = 900, call_now = false, autostart = true, callback = refresh })

refresh()

return wibox.widget({
	{
		{
			{
				layout = wibox.layout.align.horizontal,
				{
					layout = wibox.layout.fixed.vertical,
					date_label,
					month_label,
				},
				nil,
				refresh_button,
			},
			calendar_box,
			spacing = dpi(8),
			layout = wibox.layout.fixed.vertical,
		},
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	bg = beautiful.groups_bg,
	shape = function(cr, width, height)
		gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
	end,
	widget = wibox.container.background,
})
