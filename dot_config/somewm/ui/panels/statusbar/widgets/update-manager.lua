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
local function parse_pacman_updates(stdout)
	local packages = {}
	local count = 0
	for line in stdout:gmatch("[^\r\n]+") do
		-- checkupdates output format: "package old_version -> new_version"
		local pkg_name, old_ver, new_ver = line:match("^(%S+)%s+(%S+)%s+%->%s+(%S+)$")
		if pkg_name and old_ver and new_ver then
			table.insert(packages, string.format("%s (%s → %s)", pkg_name, old_ver, new_ver))
			count = count + 1
		end
	end
	return count, packages
end

local function parse_upstream_updates(stdout)
	local packages = {}
	local count = 0
	for line in stdout:gmatch("[^\r\n]+") do
		-- Machine-readable format: "package old_version new_version"
		local pkg_name, old_ver, new_ver = line:match("^(%S+)%s+(%S+)%s+(%S+)$")
		if pkg_name and old_ver and new_ver then
			table.insert(packages, string.format("%s (%s → %s)", pkg_name, old_ver, new_ver))
			count = count + 1
		end
	end
	return count, packages
end
local function update_widget_state(
	pacman_count,
	pacman_packages,
	upstream_count,
	upstream_packages
)
	local total_updates = pacman_count + upstream_count
	if total_updates > 0 then
		widget.icon:set_image(icons.widgets.update.shield_alert)
		local tooltip_text = string.format("Updates available: %d total\n", total_updates)
		if pacman_count > 0 then
			tooltip_text = tooltip_text .. string.format("\nPacman (%d):\n", pacman_count)
			for i, pkg in ipairs(pacman_packages) do
				tooltip_text = tooltip_text .. "• " .. pkg .. "\n"
				if i >= 10 and #pacman_packages > 10 then
					tooltip_text = tooltip_text .. string.format("• ... and %d more\n", #pacman_packages - 10)
					break
				end
			end
		end
		if upstream_count > 0 then
			tooltip_text = tooltip_text .. string.format("\nUpstream (%d):\n", upstream_count)
			for i, pkg in ipairs(upstream_packages) do
				tooltip_text = tooltip_text .. "• " .. pkg .. "\n"
				if i >= 10 and #upstream_packages > 10 then
					tooltip_text = tooltip_text .. string.format("• ... and %d more\n", #upstream_packages - 10)
					break
				end
			end
		end
		update_tooltip.markup = tooltip_text
	else
		widget.icon:set_image(icons.widgets.update.shield_check)
		update_tooltip.markup = "System is up to date"
	end
end
-- Check for updates
local function check_updates()
	widget.icon:set_image(icons.widgets.update.shield)
	update_tooltip.markup = "Checking for updates..."
	local pacman_count, pacman_packages = 0, {}
	local upstream_count, upstream_packages = 0, {}
	local checks_completed = 0
	local function on_check_complete()
		checks_completed = checks_completed + 1
		if checks_completed == 2 then
			update_widget_state(
				pacman_count,
				pacman_packages,
				upstream_count,
				upstream_packages
			)
		end
	end
	-- Check Pacman updates (checkupdates is safe, no root needed, no db lock)
	awful.spawn.easy_async("checkupdates", function(stdout, stderr, exit_reason, exit_code)
		-- checkupdates exits 2 when no updates, 0 when updates found
		if exit_code == 0 or exit_code == 2 then
			pacman_count, pacman_packages = parse_pacman_updates(stdout)
		end
		on_check_complete()
	end)

	-- Check Upstream updates
	awful.spawn.easy_async(
		os.getenv("HOME") .. "/.upstream/symlinks/upstream upgrade --check --machine-readable",
		function(stdout, stderr, exit_reason, exit_code)
			if exit_code == 0 then
				upstream_count, upstream_packages = parse_upstream_updates(stdout)
			end
			on_check_complete()
		end
	)
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
