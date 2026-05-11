local services = {}

services.audio = require("services.audio")
services.brightness = require("services.brightness")
services.power = require("services.power")
services.bluetooth = require("services.bluetooth")
services.network = require("services.network")
services.media = require("services.media")

services.audio.start()
services.brightness.start()
services.power.start()
services.bluetooth.start()
services.network.start()
services.media.start()

return services
