local gears = require("gears")
local timeout = 0.01
local step = 0.02

-- Table to track active animations
local active_animations = {}

local flashfocus = function(c)
	if c and #c.screen.clients > 1 then
		-- Stop any existing animation for this client and restore its opacity
		if active_animations[c] then
			active_animations[c].timer:stop()
			if active_animations[c].original_opacity and c.valid then
				c.opacity = active_animations[c].original_opacity
			end
			active_animations[c] = nil
		end

		local old = c.opacity
		local op = c.opacity * 0.6
		c.opacity = op
		local q = op

		local g = gears.timer({
			timeout = timeout,
			call_now = false,
			autostart = true,
		})

		-- Store animation info
		active_animations[c] = {
			timer = g,
			original_opacity = old,
		}

		g:connect_signal("timeout", function()
			if not c.valid then
				active_animations[c] = nil
				g:stop()
				return
			end

			if q >= old then
				c.opacity = old
				g:stop()
				active_animations[c] = nil
			else
				c.opacity = q
				q = q + step
			end
		end)
	end
end

-- Clean up when client is unmanaged
client.connect_signal("unmanage", function(c)
	if active_animations[c] then
		active_animations[c].timer:stop()
		active_animations[c] = nil
	end
end)

client.connect_signal("focus", flashfocus)
