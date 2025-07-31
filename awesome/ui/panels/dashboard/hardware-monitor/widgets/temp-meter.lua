local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local watch = awful.widget.watch
local dpi = beautiful.xresources.apply_dpi
local icons = require('theme.icons')

local temp = wibox.widget.textbox()
temp.font = beautiful.widget_text



local slider = wibox.widget {
	nil,
	{
		id 				 = 'temp_status',
		max_value     	 = 100,
		value         	 = 29,
		forced_height 	 = dpi(2),
		color 			 = beautiful.fg_normal,
		background_color = beautiful.groups_bg,
		shape 			 = gears.shape.rounded_rect,
		widget        	 = wibox.widget.progressbar
	},
	nil,
	expand = 'none',
	layout = wibox.layout.align.vertical
}

local max_temp = 100

awful.spawn.easy_async_with_shell(
	[[
	temp_path=null
	for i in /sys/class/hwmon/hwmon*/temp*_input;
	do
		temp_path="$(echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null ||
			echo $(basename ${i%_*})) $(readlink -f $i)");"

		label="$(echo $temp_path | awk '{print $2}')"

		if [ "$label" = "Package" ];
		then
			echo ${temp_path} | awk '{print $5}' | tr -d ';\n'
			exit;
		fi
	done
	]],
	function(stdout)
		local temp_path = stdout:gsub('%\n', '')
		if temp_path == '' or not temp_path then
			temp_path = '/sys/class/thermal/thermal_zone0/temp'
		end

		watch(
			[[
			sh -c "cat ]] .. temp_path .. [["
			]],
			2,
			function(_, stdout)
				local temperature = stdout:match('(%d+)')
				slider.temp_status:set_value((temperature / 1000) / max_temp * 100)
				temp.text = math.floor(temperature / 1000) .. "°C"
				collectgarbage('collect')
			end
		)
	end
)


local temp_meter = wibox.widget {
	{
		{
			{
				{
					image = icons.applets.resources.temp,
					resize = true,
					widget = wibox.widget.imagebox
				},
				top = dpi(12),
				bottom = dpi(12),
				widget = wibox.container.margin
			},
			{
				temp,
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

return temp_meter
