local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local watch = require('awful.widget.watch')
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local cpu = wibox.widget.textbox()
cpu.font = beautiful.widget_text

local total_prev = 0
local idle_prev = 0


local slider = wibox.widget {
	nil,
	{
		id               = 'cpu_usage',
		max_value        = 100,
		value            = 0,
		forced_height    = dpi(2),
		color            = beautiful.fg_normal,
		background_color = beautiful.groups_bg,
		shape            = gears.shape.rounded_rect,
		widget           = wibox.widget.progressbar
	},
	nil,
	expand = 'none',
	layout = wibox.layout.align.vertical
}

watch([[bash -c "cat /proc/stat | grep '^cpu '"]], 2, function(_, stdout, _, _, exit_code)
	if exit_code ~= 0 then
		cpu.text = "Err"
		return
	end

	local user, nice, system, idle = stdout:match("(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
	if not (user and nice and system and idle) then
		cpu.text = "N/A"
		return
	end

	local total = user + nice + system + idle
	local diff_idle = idle - idle_prev
	local diff_total = total - total_prev
	local diff_usage = 0
	if diff_total ~= 0 then
		diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10
	end

	cpu.text = math.floor(diff_usage) .. "%"
	slider.cpu_usage:set_value(math.floor(diff_usage))

	if diff_usage < 10 then cpu.text = " " .. cpu.text end

	total_prev = total
	idle_prev = idle
end)

local cpu_meter = wibox.widget { {
	{
		{
			{
				image = icons.applets.resources.cpu,
				resize = true,
				widget = wibox.widget.imagebox
			},
			top = dpi(12),
			bottom = dpi(12),
			widget = wibox.container.margin
		},
		{
			cpu,
			fg = beautiful.fg_normal,
			widget = wibox.container.background
		},
		spacing      = dpi(4),
		layout       = wibox.layout.fixed.horizontal,
		forced_width = dpi(65),
	},
	slider,
	spacing = dpi(12),
	layout = wibox.layout.fixed.horizontal
},
	left = dpi(24),
	right = dpi(24),
	forced_height = dpi(48),
	widget = wibox.container.margin
}

return cpu_meter
