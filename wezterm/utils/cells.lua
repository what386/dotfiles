-- Cell formatting utilities for wezterm.format
-- This is a complex utility class for building formatted text segments

local attr = {}

function attr.intensity(type)
    return { Attribute = { Intensity = type } }
end

function attr.italic()
    return { Attribute = { Italic = true } }
end

function attr.underline(type)
    return { Attribute = { Underline = type } }
end

local Cells = {}
Cells.__index = Cells

-- Attribute generator for wezterm.format
Cells.attr = setmetatable(attr, {
    __call = function(_, ...)
        return { ... }
    end,
})

function Cells:new()
    return setmetatable({
        segments = {},
    }, self)
end

function Cells:add_segment(segment_id, text, color, attributes)
    color = color or {}
    local items = {}

    if color.bg then
        assert(color.bg ~= "UNSET", "Cannot use UNSET when adding new segment")
        table.insert(items, { Background = { Color = color.bg } })
    end
    if color.fg then
        assert(color.fg ~= "UNSET", "Cannot use UNSET when adding new segment")
        table.insert(items, { Foreground = { Color = color.fg } })
    end
    if attributes and #attributes > 0 then
        for _, attr_ in ipairs(attributes) do
            table.insert(items, attr_)
        end
    end
    table.insert(items, { Text = text })
    table.insert(items, "ResetAttributes")

    self.segments[segment_id] = {
        items = items,
        has_bg = color.bg ~= nil,
        has_fg = color.fg ~= nil,
    }

    return self
end

function Cells:_check_segment(segment_id)
    if not self.segments[segment_id] then
        error('Segment "' .. segment_id .. '" not found')
    end
end

function Cells:update_segment_text(segment_id, text)
    self:_check_segment(segment_id)
    local idx = #self.segments[segment_id].items - 1
    self.segments[segment_id].items[idx] = { Text = text }
    return self
end

function Cells:update_segment_colors(segment_id, color)
    assert(type(color) == "table", "Color must be a table")
    self:_check_segment(segment_id)

    local has_bg = self.segments[segment_id].has_bg
    local has_fg = self.segments[segment_id].has_fg

    if color.bg then
        if has_bg and color.bg == "UNSET" then
            table.remove(self.segments[segment_id].items, 1)
            has_bg = false
        elseif has_bg then
            self.segments[segment_id].items[1] = { Background = { Color = color.bg } }
        else
            table.insert(self.segments[segment_id].items, 1, { Background = { Color = color.bg } })
            has_bg = true
        end
    end

    if color.fg then
        local fg_idx = has_bg and 2 or 1
        if has_fg and color.fg == "UNSET" then
            table.remove(self.segments[segment_id].items, fg_idx)
            has_fg = false
        elseif has_fg then
            self.segments[segment_id].items[fg_idx] = { Foreground = { Color = color.fg } }
        else
            table.insert(self.segments[segment_id].items, fg_idx, { Foreground = { Color = color.fg } })
            has_fg = true
        end
    end

    self.segments[segment_id].has_bg = has_bg
    self.segments[segment_id].has_fg = has_fg
    return self
end

function Cells:render(ids)
    local cells = {}
    for _, id in ipairs(ids) do
        self:_check_segment(id)
        for _, item in pairs(self.segments[id].items) do
            table.insert(cells, item)
        end
    end
    return cells
end

function Cells:render_all()
    local cells = {}
    for _, segment in pairs(self.segments) do
        for _, item in pairs(segment.items) do
            table.insert(cells, item)
        end
    end
    return cells
end

function Cells:reset()
    self.segments = {}
end

return Cells
