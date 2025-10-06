-- Simple utility functions
local M = {}

-- Clamp a value between min and max
function M.clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

-- Round a number
function M.round(x, increment)
    if increment then
        return M.round(x / increment) * increment
    end
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

-- Split a string by separator
function M.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return M
