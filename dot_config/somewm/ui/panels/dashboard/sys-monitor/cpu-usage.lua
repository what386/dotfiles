local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local icons = require("theme.icons")

local function new()
	local meter_info =
		wibox.widget({ text = "--%", font = "Inter Bold 10", align = "left", widget = wibox.widget.textbox })
	local meter_name =
		wibox.widget({ text = "CPU", font = "Inter Bold 10", align = "left", widget = wibox.widget.textbox })
	local icon = wibox.widget({ image = icons.applets.resources.cpu, resize = true, widget = wibox.widget.imagebox })
	local meter_icon = wibox.widget({
		{ icon, margins = dpi(5), widget = wibox.container.margin },
		bg = beautiful.groups_bg,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
		end,
		widget = wibox.container.background,
	})
	local total_bar = wibox.widget({
		max_value = 100,
		value = 0,
		forced_height = dpi(16),
		color = "#f2f2f2EE",
		background_color = "#ffffff20",
		shape = gears.shape.rounded_rect,
		widget = wibox.widget.progressbar,
	})
	local core_rows = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(3),
	})
	local core_bars, previous = {}, {}
	local paired_rows = {}

	local function add_core(core)
		if core_bars[core] then
			return
		end
		local bar = wibox.widget({
			max_value = 100,
			value = 0,
			forced_height = dpi(8),
			color = "#f2f2f2EE",
			background_color = "#ffffff20",
			shape = gears.shape.rounded_rect,
			widget = wibox.widget.progressbar,
		})
		core_bars[core] = bar
		local row_index = math.floor(tonumber(core) / 2) + 1
		local column_index = tonumber(core) % 2 + 1
		if not paired_rows[row_index] then
			local cells = { wibox.container.background(), wibox.container.background() }
			paired_rows[row_index] = cells
			core_rows:add(wibox.widget({
				cells[1],
				cells[2],
				spacing = dpi(12),
				layout = wibox.layout.flex.horizontal,
			}))
		end
		paired_rows[row_index][column_index]:set_widget(wibox.widget({
			{
				{
					text = string.format("C%s", core),
					font = "Inter Regular 9",
					forced_width = dpi(24),
					widget = wibox.widget.textbox,
				},
				right = dpi(5),
				widget = wibox.container.margin,
			},
			{ bar, valign = "center", widget = wibox.container.place },
			nil,
			layout = wibox.layout.align.horizontal,
		}))
	end

	local widget = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(5),
		{
			layout = wibox.layout.align.horizontal,
			{ layout = wibox.layout.fixed.horizontal, forced_height = dpi(24), forced_width = dpi(24), meter_icon },
			meter_name,
			meter_info,
		},
		{
			{
				{
					{ text = "Util", font = "Inter Regular 9", forced_width = dpi(24), widget = wibox.widget.textbox },
					right = dpi(5),
					widget = wibox.container.margin,
				},
				{ total_bar, valign = "center", widget = wibox.container.place },
				nil,
				layout = wibox.layout.align.horizontal,
			},
			bottom = dpi(5),
			widget = wibox.container.margin,
		},
		core_rows,
	})

	local function update()
		local f = io.open("/proc/stat", "r")
		if not f then
			return
		end
		local total_usage, usage_count = 0, 0
		for line in f:lines() do
			local core, user, nice, system, idle, iowait, irq, softirq, steal =
				line:match("^cpu(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
			if core then
				local total = user + nice + system + idle + iowait + irq + softirq + steal
				local old = previous[core]
				previous[core] = { total = total, idle = idle + iowait }
				add_core(core)
				if old and total > old.total then
					local usage = math.max(
						0,
						math.min(100, 100 * ((total - old.total) - ((idle + iowait) - old.idle)) / (total - old.total))
					)
					core_bars[core]:set_value(usage)
					total_usage, usage_count = total_usage + usage, usage_count + 1
				end
			end
		end
		f:close()
		if usage_count > 0 then
			local average = total_usage / usage_count
			total_bar:set_value(average)
			meter_info:set_text(string.format("%.1f%%", average))
		end
	end

	local timer = gears.timer({ timeout = 2, autostart = false, call_now = true, callback = update })
	function widget:start()
		if not timer.started then
			timer:start()
		end
	end
	function widget:stop()
		timer:stop()
	end
	return widget
end

return new
