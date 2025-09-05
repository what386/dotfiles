local M = {}

function M.apply(config)
    -- Window and behavior settings
    config.window_decorations = "RESIZE"
    config.window_close_confirmation = "AlwaysPrompt"
    config.automatically_reload_config = true
    config.exit_behavior = "CloseOnCleanExit"
    config.exit_behavior_messaging = "Verbose"
    config.status_update_interval = 1000
    config.scrollback_lines = 20000

    -- Hyperlink detection rules
    config.hyperlink_rules = {
        -- URL in parens: (URL)
        {
            regex = "\\((\\w+://\\S+)\\)",
            format = "$1",
            highlight = 1,
        },
        -- URL in brackets: [URL]
        {
            regex = "\\[(\\w+://\\S+)\\]",
            format = "$1",
            highlight = 1,
        },
        -- URL in curly braces: {URL}
        {
            regex = "\\{(\\w+://\\S+)\\}",
            format = "$1",
            highlight = 1,
        },
        -- URL in angle brackets: <URL>
        {
            regex = "<(\\w+://\\S+)>",
            format = "$1",
            highlight = 1,
        },
        -- URLs not wrapped in brackets
        {
            regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
            format = "$0",
        },
        -- Implicit mailto link
        {
            regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
            format = "mailto:$0",
        },
    }
end

return M
