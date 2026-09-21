local ruled = require("ruled")

local function map_to_primary_tag(class, tag_index)
	ruled.client.append_rule({
		rule = { class = class },
		properties = { screen = 1 },
		callback = function(c)
			local target = screen[1] or screen.primary or c.screen
			if not target then return end
			c.screen = target
			local tag = target.tags[tag_index]
			if tag then c:move_to_tag(tag) end
		end,
	})
end

map_to_primary_tag("org.wezfurlong.wezterm", 1)
map_to_primary_tag("zen", 3)
map_to_primary_tag("obsidian", 4)
map_to_primary_tag("vesktop", 8)
map_to_primary_tag("eu.betterbird.Betterbird", 9)
map_to_primary_tag("com.github.th_ch.youtube_music", 10)
