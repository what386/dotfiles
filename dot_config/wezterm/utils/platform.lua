local wezterm = require("wezterm")

local function is_found(str, pattern)
    return string.find(str, pattern) ~= nil
end

-- Simple platform detection
local target = wezterm.target_triple
local is_win = is_found(target, "windows")
local is_linux = is_found(target, "linux")
local is_mac = is_found(target, "apple")

local os_name
if is_win then
    os_name = "windows"
elseif is_linux then
    os_name = "linux"
elseif is_mac then
    os_name = "mac"
else
    error("Unknown platform: " .. target)
end

-- Export platform information
return {
    os = os_name,
    is_win = is_win,
    is_linux = is_linux,
    is_mac = is_mac,
}
