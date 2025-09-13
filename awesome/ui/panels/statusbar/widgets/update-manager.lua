local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local watch = awful.widget.watch
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.update.shield,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(6),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

local update_tooltip = awful.tooltip({
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

local function parse_apt_updates(stdout)
	local packages = {}
	local count = 0

	for line in stdout:gmatch("[^\r\n]+") do
		-- Match lines like: "package-name/repository version [size]"
		local package_name = line:match("^([^/]+)/")
		if package_name then
			table.insert(packages, package_name)
			count = count + 1
		end
	end

	return count, packages
end

local function parse_flatpak_updates(stdout)
	local packages = {}
	local count = 0

	for line in stdout:gmatch("[^\r\n]+") do
		-- Flatpak output format: "app-id	version	arch	branch	remote"
		local app_name = line:match("^([^\t]+)")
		if app_name and app_name ~= "" then
			-- Extract readable name if possible, otherwise use app-id
			local display_name = app_name:match("%.([^%.]+)$") or app_name
			table.insert(packages, display_name)
			count = count + 1
		end
	end

	return count, packages
end

local function update_widget_state(apt_count, apt_packages, flatpak_count, flatpak_packages)
	local total_updates = apt_count + flatpak_count

	if total_updates > 0 then
		widget.icon:set_image(icons.widgets.update.shield_alert)

		local tooltip_text = string.format("Updates available: %d total\n", total_updates)

		if apt_count > 0 then
			tooltip_text = tooltip_text .. string.format("\nAPT (%d):\n", apt_count)
			for i, pkg in ipairs(apt_packages) do
				tooltip_text = tooltip_text .. "• " .. pkg .. "\n"
				-- Limit display to prevent huge tooltips
				if i >= 10 and #apt_packages > 10 then
					tooltip_text = tooltip_text .. string.format("• ... and %d more\n", #apt_packages - 10)
					break
				end
			end
		end

		if flatpak_count > 0 then
			tooltip_text = tooltip_text .. string.format("\nFlatpak (%d):\n", flatpak_count)
			for i, pkg in ipairs(flatpak_packages) do
				tooltip_text = tooltip_text .. "• " .. pkg .. "\n"
				if i >= 10 and #flatpak_packages > 10 then
					tooltip_text = tooltip_text .. string.format("• ... and %d more\n", #flatpak_packages - 10)
					break
				end
			end
		end

		update_tooltip.markup = tooltip_text
		--widget_button.visible = true
	else
		widget.icon:set_image(icons.widgets.update.shield_check)
		update_tooltip.markup = "System is up to date"
	end
end

-- Check for updates
local function check_updates()
	widget.icon:set_image(icons.widgets.update.shield)
	update_tooltip.markup = "Checking for updates..."

	local apt_count, apt_packages = 0, {}
	local flatpak_count, flatpak_packages = 0, {}
	local checks_completed = 0

	local function on_check_complete()
		checks_completed = checks_completed + 1
		if checks_completed == 2 then
			update_widget_state(apt_count, apt_packages, flatpak_count, flatpak_packages)
		end
	end

	-- Check APT updates
	awful.spawn.easy_async("apt list --upgradable", function(stdout, stderr, exit_reason, exit_code)
		if exit_code == 0 then
			apt_count, apt_packages = parse_apt_updates(stdout)
		end
		on_check_complete()
	end)

	-- Check Flatpak updates
	awful.spawn.easy_async("flatpak remote-ls --updates", function(stdout, stderr, exit_reason, exit_code)
		if exit_code == 0 then
			flatpak_count, flatpak_packages = parse_flatpak_updates(stdout)
		end
		on_check_complete()
	end)
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	check_updates()
end)))

gears.timer({
	timeout = 1800, -- Check every 30 minutes
	call_now = true,
	autostart = true,
	callback = check_updates,
})

return widget_button
