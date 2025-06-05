-- _common/main.lua
-- Shared UI and utilities module initialization

---@global
RIOSODU_SHARED = RIOSODU_SHARED or {}

function riosodu_shared_init()
    if RIOSODU_SHARED.initialized then
        return
    end

    -- Initialize namespaces
    RIOSODU_SHARED = {}
    RIOSODU_SHARED.UIDEF = {}
    RIOSODU_SHARED.utils = {}
    RIOSODU_SHARED.debug = {}
    RIOSODU_SHARED.UI = {}

    -- Load config from either standalone mod or host mod
    RIOSODU_SHARED.config = SMODS.current_mod.config or {}
    if SMODS.current_mod.id == 'riosodu_shared' then
        RIOSODU_SHARED._is_standalone = true
    end

    -- Determine include prefix based on installation location
    local is_mod = SMODS.current_mod.id == 'riosodu_shared'
    local prefix = is_mod and '' or 'common/'

    local function include(path)
        local chunk = SMODS.load_file(prefix .. path, SMODS.current_mod.id)
        if chunk then chunk() end
    end

    -- Load shared components
    include('ui/components.lua')
    include('debug.lua')
    include('ui/tabs.lua')

    ---@param mod_id string The ID of the mod calling this function
    ---@param filename string The path to the file relative to the mod's directory
    function RIOSODU_SHARED.include_mod_file(mod_id, filename)
        local chunk = SMODS.load_file(filename, mod_id)
        if chunk then
            chunk()
        end
    end

    -- Set config tab hook for main mod
    if SMODS.current_mod.id == 'riosodu_shared' then
        SMODS.current_mod.config_tab = function()
            return RIOSODU_SHARED.UI.createDebugSettingsTabDefinition()
        end
    end

    RIOSODU_SHARED.initialized = true
    print("[RIOSODU_SHARED] Initialization complete.")
end

-- Initialize when loaded as `common` mod or included as common folder
riosodu_shared_init()
