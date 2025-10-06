local M = {}

function M.apply(config)
    -- SSH domains configuration
    config.ssh_domains = {
        {
            name = "wsl.ssh",
            remote_address = "localhost",
            multiplexing = "None",
            assume_shell = "Posix",
        },
    }

    -- Unix domains (empty for now)
    config.unix_domains = {}

    -- WSL domains configuration
    config.wsl_domains = {
        {
            name = "WSL:Ubuntu",
            distribution = "Ubuntu",
            username = "bmorin",
            default_cwd = "/home/bmorin/",
        },
    }
end

return M
