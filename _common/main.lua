-- _common/main.lua
-- Shared UI and utilities module initialization

RIOSODU_SHARED = RIOSODU_SHARED or {}

function riosodu_shared_init()
    if RIOSODU_SHARED.initialized then
        return
    end

    -- Reset RIOSODU_SHARED namespace
    RIOSODU_SHARED = {}
    RIOSODU_SHARED.UIDEF = {}
    RIOSODU_SHARED.utils = {}

    -- Determine include prefix based on installation location
    local is_mod = SMODS.current_mod.id == 'riosodu_shared'
    local prefix = is_mod and '' or 'common/'

    local function include(path)
        local chunk = SMODS.load_file(prefix .. path, SMODS.current_mod.id)
        if chunk then chunk() end
    end

    -- Load shared UI components
    include('ui/components.lua')

    RIOSODU_SHARED.initialized = true
end

-- Initialize when loaded as `common` mod or included as common folder
riosodu_shared_init()
