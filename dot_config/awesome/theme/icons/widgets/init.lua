local widgets = {}

widgets.server = require("theme.icons.widgets.server")
widgets.update = require("theme.icons.widgets.update")
widgets.package = require("theme.icons.widgets.package")
widgets.battery = require("theme.icons.widgets.battery")
widgets.brightness = require("theme.icons.widgets.brightness")
widgets.volume = require("theme.icons.widgets.volume")
widgets.microphone = require("theme.icons.widgets.microphone")
widgets.bluetooth = require("theme.icons.widgets.bluetooth")

local network = require("theme.icons.widgets.network")
widgets.wifi = network.wifi
widgets.ethernet = network.ethernet
widgets.airplane = network.airplane

return widgets
