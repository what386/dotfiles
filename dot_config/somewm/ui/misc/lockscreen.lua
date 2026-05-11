local wibox = require("wibox")
local awful = require("awful")

-- Create lock surfaces
local lock_wb = wibox({
    visible = false,
    ontop = true,
    type = "desktop",
})

-- Register as lock surface
awesome.set_lock_surface(lock_wb)

-- Handle multi-monitor: add covers for other screens
for s in screen do
    if s ~= screen.primary then
        local cover = wibox({
            screen = s,
            visible = false,
            ontop = true,
            bg = "#000000",
            x = s.geometry.x,
            y = s.geometry.y,
            width = s.geometry.width,
            height = s.geometry.height,
        })
        awesome.add_lock_cover(cover)
    end
end

-- React to lock activation
awesome.connect_signal("lock::activate", function()
    -- Show your surfaces, start keygrabber
    lock_wb.visible = true
    local password = ""

    awful.keygrabber {
        autostart = true,
        keypressed_callback = function(_, _, key)
            if key == "Return" then
                awesome.authenticate(password)
                awesome.unlock()
                password = ""
            elseif key == "BackSpace" then
                password = password:sub(1, -2)
            elseif #key == 1 then
                password = password .. key
            end
        end,
    }
end)

awesome.connect_signal("lock::deactivate", function()
    lock_wb.visible = false
end)

-- Dim displays after 2 minutes
awesome.set_idle_timeout("dim", 120, function()
    awesome.dpms_off()
end)

-- Turn off displays after 3 minutes, lock after 5
awesome.set_idle_timeout("dpms", 180, function()
    awesome.dpms_off()
end)

-- Lock after 5 minutes
awesome.set_idle_timeout("lock", 300, function()
    awesome.lock()
end)

-- lock on suspend
awesome.connect_signal("logind::prepare_sleep", function(going_to_sleep)
    if going_to_sleep then
        awesome.lock()
    end
end)

-- disable lockscreen while an app is fullscreen
client.connect_signal("property::fullscreen", function()
    local dominated = false
    for _, c in ipairs(client.get()) do
        if c.fullscreen then dominated = true; break end
    end
    awesome.idle_inhibit = dominated
end)

-- widget idea?
--
--local idle_widget = wibox.widget.textbox()

--local function update_idle_widget()
--    if not awesome.idle_inhibited then
--        idle_widget.text = " "
--        return
--    end
--
--    -- Show which app is inhibiting (if any)
--    local inhibitors = awesome.inhibitors
--    if #inhibitors > 0 and inhibitors[1].client then
--        idle_widget.text = "  " .. inhibitors[1].client.class
--    else
--        idle_widget.text = " "
--    end
--end

--update_idle_widget()
--awesome.connect_signal("property::idle_inhibited", update_idle_widget)
