local wezterm = require("wezterm")
local platform = require("utils.platform")

local M = {}

-- Available backends by platform
local AVAILABLE_BACKENDS = {
    windows = { "Dx12", "Vulkan", "Gl" },
    linux = { "Vulkan", "Gl" },
    mac = { "Metal" },
}

-- Get enumerated GPUs
local ENUMERATED_GPUS = wezterm.gui.enumerate_gpus()

-- Build adapter lookup table
local adapters = {
    DiscreteGpu = {},
    IntegratedGpu = {},
    Cpu = {},
    Other = {},
}

-- Populate adapter lookup table
for _, adapter in ipairs(ENUMERATED_GPUS) do
    if not adapters[adapter.device_type] then
        adapters[adapter.device_type] = {}
    end
    adapters[adapter.device_type][adapter.backend] = adapter
end

-- Get platform-specific backends
local backends = AVAILABLE_BACKENDS[platform.os] or {}
local preferred_backend = backends[1]

function M:pick_best()
    -- Priority order: DiscreteGpu > IntegratedGpu > Other > Cpu
    local adapter_options = adapters.DiscreteGpu
    local backend = preferred_backend

    if not next(adapter_options) then
        adapter_options = adapters.IntegratedGpu
    end

    if not next(adapter_options) then
        adapter_options = adapters.Other
        backend = "Gl" -- Force OpenGL for "Other" devices
    end

    if not next(adapter_options) then
        adapter_options = adapters.Cpu
    end

    if not next(adapter_options) then
        wezterm.log_error("No GPU adapters found. Using Default Adapter.")
        return nil
    end

    local adapter_choice = adapter_options[backend]

    if not adapter_choice then
        wezterm.log_error("Preferred backend (" .. (backend or "nil") .. ") not available. Using Default Adapter.")
        return nil
    end

    return adapter_choice
end

function M:pick_manual(backend, device_type)
    local adapter_options = adapters[device_type]

    if not adapter_options or not next(adapter_options) then
        wezterm.log_error("No GPU adapters found for device type: " .. device_type)
        return nil
    end

    local adapter_choice = adapter_options[backend]

    if not adapter_choice then
        wezterm.log_error("Backend (" .. backend .. ") not available for device type: " .. device_type)
        return nil
    end

    return adapter_choice
end

return M
