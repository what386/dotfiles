local naughty = require("naughty")

naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification({
		urgency = "critical",
		title = "A configuration error occured" .. (startup and " during startup"),
		message = message,
		app_name = "System Notification",
		icon = beautiful.awesome_icon,
	})
end)

awesome.connect_signal("debug::error", function(err)
	naughty.notification({
		urgency = "critical",
		title = "An error occured in the Awesome process.",
		message = err,
		app_name = "System Notification",
		icon = beautiful.awesome_icon,
	})
end)
