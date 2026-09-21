local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local icons = require("theme.icons")

local function new()
	local meter_info = wibox.widget({
		text = "GPU --%",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})
	local meter_name = wibox.widget({
		text = "GPU",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local icon = wibox.widget({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			image = icons.applets.resources.gpu,
			resize = true,
			widget = wibox.widget.imagebox,
		},
		nil,
	})

	local meter_icon = wibox.widget({
		{
			icon,
			margins = dpi(5),
			widget = wibox.container.margin,
		},
		bg = beautiful.groups_bg,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
		end,
		widget = wibox.container.background,
	})

	local gpu_usage = wibox.widget({ max_value = 100, value = 0, forced_height = dpi(10), color = "#f2f2f2EE", background_color = "#ffffff20", shape = gears.shape.rounded_rect, widget = wibox.widget.progressbar })
	local gpu_vram = wibox.widget({ max_value = 100, value = 0, forced_height = dpi(10), color = "#f2f2f2AA", background_color = "#ffffff20", shape = gears.shape.rounded_rect, widget = wibox.widget.progressbar })
	local function metric_row(label, bar)
		return { { text = label, font = "Inter Regular 9", forced_width = dpi(36), widget = wibox.widget.textbox }, bar, spacing = dpi(5), layout = wibox.layout.fixed.horizontal }
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
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(4),
			metric_row("Util", gpu_usage),
			metric_row("VRAM", gpu_vram),
		},
	})

	-- Prefer the driver's utilization counter.  The card number is not stable
	-- across machines, so discover the first usable DRM device at each poll.
	-- Intel's frequency files remain as a fallback for older systems.
	local gpu_stats_command = [[
for device in /sys/class/drm/card*/device; do
	if [ -r "$device/gpu_busy_percent" ]; then
		busy=$(cat "$device/gpu_busy_percent")
		used=$(cat "$device/mem_info_vram_used" 2>/dev/null || printf '0')
		total=$(cat "$device/mem_info_vram_total" 2>/dev/null || printf '0')
		printf 'amd\t%s\t%s\t%s\n' "$busy" "$used" "$total"
		exit 0
	fi
done
for device in /sys/class/drm/card*/device; do
	if [ -r "$device/gt_cur_freq_mhz" ] && [ -r "$device/gt_max_freq_mhz" ]; then
		printf 'intel\t%s\t%s\n' "$(cat "$device/gt_cur_freq_mhz")" "$(cat "$device/gt_max_freq_mhz")"
		exit 0
	fi
done
]]

	local function update()
		awful.spawn.easy_async_with_shell(gpu_stats_command, function(out)
			-- Shell commands may leave a leading newline in stdout. Parse the
			-- numeric fields explicitly so an empty optional field cannot make a
			-- valid AMD reading look unavailable.
			out = out:gsub("^%s+", "")
			local kind, first, second, third = out:match("^(%a+)%s+(%d+)%s+(%d+)%s+(%d+)")
			if not kind then
				kind, first, second = out:match("^(%a+)%s+(%d+)%s+(%d+)")
			end
			if kind == "amd" then
				local busy = tonumber(first)
				local used = tonumber(second)
				local total = tonumber(third)
				if not busy then
					return
				end

				gpu_usage:set_value(math.max(0, math.min(100, busy)))
				if used and total and total > 0 then
					gpu_vram:set_value(math.max(0, math.min(100, used / total * 100)))
					local used_mib = math.floor(used / 1024 / 1024 + 0.5)
					local total_mib = math.floor(total / 1024 / 1024 + 0.5)
					meter_info:set_text(string.format("%d%% · %d/%d MiB", busy, used_mib, total_mib))
				else
					meter_info:set_text(string.format("%d%%", busy))
				end
			elseif kind == "intel" then
				local freq = tonumber(first)
				local max_freq = tonumber(second)
				if not freq or not max_freq or max_freq <= 0 then
					return
				end

				gpu_usage:set_value(math.max(0, math.min(100, freq / max_freq * 100)))
				gpu_vram:set_value(0)
				meter_info:set_text(freq .. " MHz / " .. max_freq .. " MHz")
			else
				gpu_usage:set_value(0)
				gpu_vram:set_value(0)
				meter_info:set_text("Unavailable")
			end
		end)
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
