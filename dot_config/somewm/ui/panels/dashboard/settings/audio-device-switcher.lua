local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local audio = require("services.audio")

local function escape_markup(value)
	value = tostring(value or "")
	value = value:gsub("&", "&amp;")
	value = value:gsub("<", "&lt;")
	value = value:gsub(">", "&gt;")
	return value
end

local function create_device_row(device, active, kind)
	local icon_path = kind == "sink" and icons.widgets.volume.volume_medium or icons.widgets.microphone.microphone

	local icon = wibox.widget({
		image = icon_path,
		resize = true,
		widget = wibox.widget.imagebox,
	})

	local title = wibox.widget({
		markup = active and "<b>" .. escape_markup(device.description) .. "</b>" or escape_markup(device.description),
		font = "Inter Regular 9",
		align = "left",
		valign = "center",
		ellipsize = "end",
		widget = wibox.widget.textbox,
	})

	local status_text = active and "Default" or (device.state ~= "" and device.state or "Available")
	local status = wibox.widget({
		markup = escape_markup(status_text),
		font = "Inter Regular 8",
		align = "right",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local row = wibox.widget({
		{
			{
				{
					{
						icon,
						forced_width = dpi(18),
						forced_height = dpi(18),
						widget = wibox.container.constraint,
					},
					{
						title,
						forced_width = dpi(310),
						strategy = "max",
						widget = wibox.container.constraint,
					},
					status,
					spacing = dpi(8),
					layout = wibox.layout.fixed.horizontal,
				},
				margins = { left = dpi(10), right = dpi(10), top = dpi(6), bottom = dpi(6) },
				widget = wibox.container.margin,
			},
			widget = clickable_container,
		},
		bg = active and beautiful.accent or beautiful.groups_bg,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
		end,
		widget = wibox.container.background,
	})

	row:buttons(gears.table.join(awful.button({}, 1, nil, function()
		if active then
			return
		end

		audio.set_default_device(kind, device.name)
	end)))

	return row
end

return function(args)
	args = args or {}
	local kind = args.kind or "sink"
	local title_text = args.title or (kind == "sink" and "Output Device" or "Input Device")

	local title = wibox.widget({
		text = title_text,
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local subtitle = wibox.widget({
		text = "Loading...",
		font = "Inter Regular 9",
		align = "right",
		widget = wibox.widget.textbox,
	})

	local header = wibox.widget({
		layout = wibox.layout.align.horizontal,
		title,
		nil,
		subtitle,
	})

	local device_list = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(5),
	})

	local container = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(7),
		header,
		device_list,
	})

	local function render(devices, default_device)
		device_list:reset()
		devices = devices or {}

		if #devices == 0 then
			local current_state = audio.get_state()
			subtitle:set_text(current_state.available and "None" or "Unavailable")
			device_list:add(wibox.widget({
				markup = current_state.available and "No devices found" or "Audio backend unavailable",
				font = "Inter Regular 9",
				align = "left",
				widget = wibox.widget.textbox,
			}))
			return
		end

		subtitle:set_text(tostring(#devices))
		for _, device in ipairs(devices) do
			device_list:add(create_device_row(device, device.name == default_device, kind))
		end
	end

	local function refresh()
		audio.get_devices(kind, render)
	end

	header:buttons({awful.button({}, 1, nil, refresh)})

	awesome.connect_signal("audio::devices", function(devices)
		local current_state = audio.get_state()
		if kind == "sink" then
			render(devices.sinks, current_state.default_sink)
		else
			render(devices.sources, current_state.default_source)
		end
	end)

	awesome.connect_signal("audio::default-device", function(changed_kind)
		if changed_kind == kind then
			refresh()
		end
	end)

	awesome.connect_signal("audio::error", function()
		render({}, nil)
	end)

	refresh()
	return container
end
