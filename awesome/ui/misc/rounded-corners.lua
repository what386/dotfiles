-- Required libraries
local gears = require("gears")

local function apply_rounded_corners(c)
	c.shape = function(cr, w, h)
		if not c.fullscreen then
			gears.shape.rounded_rect(cr, w, h, 6)
		else
			gears.shape.rectangle(cr, w, h)
		end
	end
end

-- Apply on manage
client.connect_signal("manage", apply_rounded_corners)

-- Reapply when client geometry change
client.connect_signal("property::geometry", apply_rounded_corners)

-- Reapply when fullscreen state changes
client.connect_signal("property::fullscreen", apply_rounded_corners)
