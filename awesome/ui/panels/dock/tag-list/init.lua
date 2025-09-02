local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local gears = require("gears")

local rubato = require("dependencies.rubato")

-- Configuration variables for underline and tag calculations
local UNDERLINE_WIDTH = dpi(45)                                 -- Width of the underline indicator
local TAG_CALC_WIDTH = dpi(60)                                  -- Expected width for tag positioning calculations (icon + margins)
local UNDERLINE_MARGIN = (TAG_CALC_WIDTH - UNDERLINE_WIDTH) / 2 -- Offset to center underline within tag width

--- Common method to create buttons.
-- @tab buttons
-- @param object
-- @return table
local function create_buttons(buttons, object)
	if buttons then
		local btns = {}
		for _, b in ipairs(buttons) do
			-- Create a proxy button object: it will receive the real
			-- press and release events, and will propagate them to the
			-- button object the user provided, but with the object as
			-- argument.
			local btn = awful.button({
				modifiers = b.modifiers,
				button = b.button,
				on_press = function()
					b:emit_signal("press", object)
				end,
				on_release = function()
					b:emit_signal("release", object)
				end,
			})
			btns[#btns + 1] = btn
		end
		return btns
	end
end

local function list_update(w, buttons, label, data, objects, base_widget)
	-- update the widgets, creating them if needed
	w:reset()

	-- Store tag positions for underline animation
	local tag_positions = {}
	local current_x = 0

	for i, o in ipairs(objects) do
		local cache = data[o]
		local ib, tb, bgb, tbm, ibm, l, bg_clickable
		if cache then
			ib = cache.ib
			tb = cache.tb
			bgb = cache.bgb
			tbm = cache.tbm
			ibm = cache.ibm
		else
			ib = wibox.widget.imagebox()
			tb = wibox.widget.textbox()
			bgb = wibox.container.background()
			tbm = wibox.widget({
				tb,
				left = dpi(4),
				right = dpi(16),
				widget = wibox.container.margin,
			})
			ibm = wibox.widget({
				ib,
				margins = dpi(10),
				widget = wibox.container.margin,
			})
			l = wibox.layout.fixed.horizontal()
			bg_clickable = clickable_container()
			-- All of this is added in a fixed widget
			l:fill_space(true)
			l:add(ibm)
			-- l:add(tbm)
			bg_clickable:set_widget(l)
			-- And all of this gets a background
			bgb:set_widget(bg_clickable)
			bgb:buttons(create_buttons(buttons, o))
			data[o] = {
				ib = ib,
				tb = tb,
				bgb = bgb,
				tbm = tbm,
				ibm = ibm,
			}
		end

		local text, bg, bg_image, icon, args = label(o, tb)
		args = args or {}
		-- The text might be invalid, so use pcall.
		if text == nil or text == "" then
			tbm:set_margins(0)
		else
			if not tb:set_markup_silently(text) then
				tb:set_markup("*<Invalid text>*")
			end
		end
		bgb:set_bg(bg)
		if type(bg_image) == "function" then
			-- TODO: Why does this pass nil as an argument?
			-- nevermind, i decided i dont care
			bg_image = bg_image(tb, o, nil, objects, i)
		end
		bgb:set_bgimage(bg_image)
		if icon then
			ib.image = icon
		else
			ibm:set_margins(0)
		end
		bgb.shape = args.shape
		bgb.shape_border_width = args.shape_border_width
		bgb.shape_border_color = args.shape_border_color

		-- Calculate tag positions using the configurable width
		tag_positions[o] = { x = current_x, width = TAG_CALC_WIDTH }
		current_x = current_x + TAG_CALC_WIDTH

		-- Store reference to the tag object in bgb for later use
		bgb._tag = o

		w:add(bgb)
	end

	-- Update underline position when tag selection changes
	if base_widget and base_widget._underline_anim then
		for _, tag in ipairs(objects) do
			if tag.selected and tag_positions[tag] then
				base_widget._underline_anim.target = tag_positions[tag].x + UNDERLINE_MARGIN
				break
			end
		end
	end
end

local tag_list = function(s)
	local taglist_container

	-- Create the main taglist widget
	local taglist_widget = awful.widget.taglist(
		s,
		awful.widget.taglist.filter.all,
		awful.util.table.join(
			awful.button({}, 1, function(t)
				t:view_only()
			end),
			awful.button({ modkey }, 1, function(t)
				if _G.client.focus then
					_G.client.focus:move_to_tag(t)
					t:view_only()
				end
			end),
			awful.button({}, 3, awful.tag.viewtoggle),
			awful.button({ modkey }, 3, function(t)
				if _G.client.focus then
					_G.client.focus:toggle_tag(t)
				end
			end),
			awful.button({}, 4, function(t)
				awful.tag.viewprev(t.screen)
			end),
			awful.button({}, 5, function(t)
				awful.tag.viewnext(t.screen)
			end)
		),
		{},
		function(w, buttons, label, data, objects)
			list_update(w, buttons, label, data, objects, taglist_container)
		end,
		wibox.layout.fixed.horizontal()
	)

	-- Create the sliding underline using the configurable width
	local underline = wibox.widget({
		widget = wibox.widget.separator,
		orientation = "horizontal",
		forced_height = dpi(5),
		forced_width = UNDERLINE_WIDTH,
		color = "#AFAFAF",
		span_ratio = 1.0,
	})

	-- Create rubato animation for the underline
	local underline_anim = rubato.timed({
		intro = 0.08,
		outro = 0.12,
		duration = 0.35,
		easing = rubato.quadratic,
		subscribed = function(pos)
			-- Update underline position
			if taglist_container then
				local underline_margin = taglist_container:get_children_by_id("underline_margin")[1]
				if underline_margin then
					underline_margin.left = pos
				end
			end
		end,
	})

	-- Create container with taglist and underline
	taglist_container = wibox.widget({
		{
			taglist_widget,
			{
				{
					underline,
					id = "underline_margin",
					widget = wibox.container.margin,
				},
				widget = wibox.container.place,
				halign = "left",
				valign = "bottom",
			},
			layout = wibox.layout.stack,
		},
		widget = wibox.container.background,
	})

	-- Store animation reference in the container for access in list_update
	taglist_container._underline_anim = underline_anim
	taglist_container._underline = underline

	local function update_selected_tag_color(screen)
		local theme = require("beautiful")

		-- Store original colors if not already stored
		if not theme._original_taglist_bg_focus then
			theme._original_taglist_bg_focus = theme.taglist_bg_focus
			theme._original_taglist_fg_focus = theme.taglist_fg_focus
		end

		-- Find the currently selected tag
		local selected_tag = screen.selected_tag
		if selected_tag then
			if #selected_tag:clients() > 0 then
				-- Selected tag has clients - use occupied colors
				theme.taglist_bg_focus = theme.taglist_bg_occupied
				theme.taglist_fg_focus = theme.taglist_fg_occupied
			else
				-- Selected tag is empty - use empty colors (or original focus colors)
				theme.taglist_bg_focus = theme.taglist_bg_empty or theme._original_taglist_bg_focus
				theme.taglist_fg_focus = theme.taglist_fg_empty or theme._original_taglist_fg_focus
			end
		end
	end

	-- Connect to tag selection changes
	local function update_underline()
		update_selected_tag_color(s)

		gears.timer.delayed_call(function()
			-- Find currently selected tag and its position
			for i, tag in ipairs(s.tags) do
				if tag.selected then
					-- Calculate position based on tag index using configurable width and center the underline
					local target_x = ((i - 1) * TAG_CALC_WIDTH) + UNDERLINE_MARGIN

					underline_anim.target = target_x
					break
				end
			end
		end)
	end

	-- Connect to tag property changes
	tag.connect_signal("property::selected", update_underline)

	-- Initial underline position
	update_underline()

	return taglist_container
end

return tag_list
