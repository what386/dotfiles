local ruled = require("ruled")


ruled.client.connect_signal("request::rules", function()
    ruled.client.append_rule {
        rule_any = { class = { "Alacritty", "kitty", "foot", "ghostty" } },
        properties = { backdrop_blur = true, opacity = 0.75 },
    }
end)

