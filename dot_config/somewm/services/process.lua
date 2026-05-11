local awful = require("awful")

local process = {}

function process.shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function process.run(command, callback)
	awful.spawn.easy_async(command, function(stdout, stderr, reason, exit_code)
		if callback then
			callback(stdout, stderr, reason, exit_code)
		end
	end)
end

function process.run_shell(command, callback)
	awful.spawn.easy_async_with_shell(command, function(stdout, stderr, reason, exit_code)
		if callback then
			callback(stdout, stderr, reason, exit_code)
		end
	end)
end

function process.spawn(command)
	awful.spawn(command, false)
end

function process.spawn_shell(command)
	awful.spawn.with_shell(command)
end

function process.watch(command, handlers)
	return awful.spawn.with_line_callback(command, handlers or {})
end

function process.command_exists(command, callback)
	process.run_shell("command -v " .. command .. " >/dev/null 2>&1", function(_, _, _, exit_code)
		callback(exit_code == 0)
	end)
end

return process
