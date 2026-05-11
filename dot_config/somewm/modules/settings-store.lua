local gears = require("gears")
local json = require("dependencies.json")

local config_dir = gears.filesystem.get_configuration_dir()
local settings_path = config_dir .. "persistent/settings.json"

local defaults = {
	autorestore_allowed = true,
	disturb_status = false,
	airplane_mode = false,
	auto_backlight_enabled = false,
}

local store = {}
local cache = nil

local function trim(text)
	return tostring(text or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function parse_bool(value)
	if type(value) == "boolean" then
		return value
	end
	if type(value) == "string" then
		local normalized = trim(value):lower()
		if normalized == "true" then
			return true
		end
		if normalized == "false" then
			return false
		end
	end
	return nil
end

local function read_all(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

local function write_all(path, content)
	local tmp_path = path .. ".tmp"
	local f = io.open(tmp_path, "w")
	if not f then
		return false
	end
	f:write(content)
	f:close()
	return os.rename(tmp_path, path)
end

local function apply_defaults(data)
	local changed = false
	for key, value in pairs(defaults) do
		if data[key] == nil then
			data[key] = value
			changed = true
		end
	end
	return changed
end

local function load()
	if cache then
		return cache
	end

	local data = {}
	local raw = read_all(settings_path)
	if raw and raw ~= "" then
		local ok, parsed = pcall(json.parse, raw)
		if ok and type(parsed) == "table" then
			data = parsed
		end
	end

	local changed = false
	if apply_defaults(data) then
		changed = true
	end

	cache = data
	if changed then
		write_all(settings_path, json.stringify(cache))
	end
	return cache
end

local function save()
	if not cache then
		return true
	end
	return write_all(settings_path, json.stringify(cache))
end

function store.get(key, default)
	local data = load()
	local value = data[key]
	if value == nil then
		return default
	end
	return value
end

function store.set(key, value)
	local data = load()
	data[key] = value
	return save()
end

function store.get_bool(key, default)
	local value = store.get(key, default)
	local parsed = parse_bool(value)
	if parsed == nil then
		return default
	end
	return parsed
end

function store.set_bool(key, value)
	return store.set(key, value and true or false)
end

function store.path()
	return settings_path
end

return store
