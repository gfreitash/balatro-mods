-- _common/main.lua
-- Shared UI and utilities module bootstrap.
--
-- This is NOT a standalone Steamodded mod anymore. Each mod bundles this file
-- under its own `common/` folder and loads it via:
--   local chunk = SMODS.load_file('common/main.lua', mod_id)
--   if chunk then chunk() end
--
-- Only the first mod to load initializes the library: the `RIOSODU_SHARED`
-- global acts as the gate, so subsequent mods simply skip initialization.

function riosodu_shared_init()
    if RIOSODU_SHARED ~= nil then
        return
    end

    RIOSODU_SHARED = {}

    -- The mod currently being loaded bootstraps the library
    local host_id = SMODS.current_mod.id

    -- Load the hardcoded internal version (used for debugging)
    local version_chunk = SMODS.load_file('common/version.lua', host_id)
    RIOSODU_SHARED.version = version_chunk and version_chunk() or 'unknown'

    -- Initialize namespaces
    RIOSODU_SHARED.UIDEF = {}
    RIOSODU_SHARED.utils = {}
    RIOSODU_SHARED.debug = {}
    RIOSODU_SHARED.UI = {}
    RIOSODU_SHARED.compat = {}
    RIOSODU_SHARED.original = {}

    -- Load shared config: defaults from common/config.lua merged with the
    -- saved config (config/riosodu_shared.jkr, same file as the old standalone
    -- mod so existing saves carry over)
    local config_chunk = SMODS.load_file('common/config.lua', host_id)
    RIOSODU_SHARED.config = config_chunk and config_chunk() or {}

    local function insert_saved_config(savedCfg, defaultCfg)
        for savedKey, savedVal in pairs(savedCfg) do
            local savedValType = type(savedVal)
            local defaultValType = type(defaultCfg[savedKey])
            if not defaultCfg[savedKey] then
                defaultCfg[savedKey] = savedVal
            elseif savedValType == "table" and defaultValType == "table" then
                insert_saved_config(savedVal, defaultCfg[savedKey])
            elseif savedVal ~= defaultCfg[savedKey] then
                defaultCfg[savedKey] = savedVal
            end
        end
    end

    local saved_config
    local loaded_saved = pcall(function()
        saved_config = load(NFS.read('config/riosodu_shared.jkr'), '=[RIOSODU_SHARED "config"]')()
    end)
    if loaded_saved and type(saved_config) == 'table' then
        insert_saved_config(saved_config, RIOSODU_SHARED.config)
    end

    function RIOSODU_SHARED.save_config()
        local success = pcall(function()
            NFS.createDirectory('config')
            assert(RIOSODU_SHARED.config and next(RIOSODU_SHARED.config))
            local serialized = 'return ' .. serialize(RIOSODU_SHARED.config)
            NFS.write('config/riosodu_shared.jkr', serialized)
        end)
        return success
    end

    -- Files are always loaded from the vendored `common/` folder
    local function include(path)
        local chunk = SMODS.load_file('common/' .. path, host_id)
        if chunk then chunk() end
    end

    -- Load shared components
    include('ui/components.lua')
    include('debug.lua')
    include('compat.lua')
    include('utils/utils.lua')

    ---@param mod_id string The ID of the mod calling this function
    ---@param filename string The path to the file relative to the mod's directory
    function RIOSODU_SHARED.include_mod_file(mod_id, filename)
        local chunk = SMODS.load_file(filename, mod_id)
        if chunk then
            chunk()
        end
    end

    --- Recursively loads all Lua files from a directory and its subdirectories.
    --- @param mod_id string The ID of the mod (e.g., "qol_bundle")
    --- @param base_directory string Path relative to mod root (e.g., "src/content")
    --- @param options? table Optional configuration:
    ---   - exclude_patterns (table): Array of filenames to skip (default: {"init.lua"})
    ---   - max_depth (number): Maximum recursion depth (default: 10)
    ---   - sort (boolean): Sort files alphabetically (default: true)
    ---   - on_error (string): "silent", "log", or "throw" (default: "log")
    --- @return number Count of files successfully loaded
    function RIOSODU_SHARED.load_directory_recursive(mod_id, base_directory, options)
        -- Apply defaults
        options = options or {}
        options.exclude_patterns = options.exclude_patterns or {"init.lua"}
        options.max_depth = options.max_depth or 10
        options.sort = options.sort ~= false -- default true
        options.on_error = options.on_error or "log"

        -- Get mod path
        local mod = SMODS.Mods[mod_id]
        if not mod then
            error(string.format("Mod '%s' not found", mod_id))
        end

        local full_path = mod.path .. base_directory

        -- Verify directory exists
        local dir_info = NFS.getInfo(full_path)
        if not dir_info or dir_info.type ~= 'directory' then
            local msg = string.format("Directory not found: %s", base_directory)
            if options.on_error == "throw" then
                error(msg)
            elseif options.on_error == "log" then
                RIOSODU_SHARED.utils.sendInfoMessage(msg)
            end
            return 0
        end

        -- Begin recursive loading
        local loaded_count = {count = 0}
        RIOSODU_SHARED._walk_and_load(mod_id, base_directory, 0, options, loaded_count)
        return loaded_count.count
    end

    --- Internal helper: recursively walk directory tree and load files
    --- @param mod_id string Mod ID
    --- @param current_path string Current directory path relative to mod root
    --- @param depth number Current recursion depth
    --- @param options table Configuration options
    --- @param loaded_count table Reference counter {count = N}
    function RIOSODU_SHARED._walk_and_load(mod_id, current_path, depth, options, loaded_count)
        -- Check depth limit
        if depth > options.max_depth then
            if options.on_error == "log" then
                RIOSODU_SHARED.utils.sendWarnMessage(
                    string.format("Max depth (%d) reached at: %s", options.max_depth, current_path)
                )
            end
            return
        end

        -- Get full filesystem path
        local mod = SMODS.Mods[mod_id]
        local full_path = mod.path .. current_path

        -- Get directory items
        local items = NFS.getDirectoryItems(full_path)
        if not items then return end

        -- Sort if requested
        if options.sort then
            table.sort(items, function(a, b) return a:lower() < b:lower() end)
        end

        -- Separate files and directories
        local files, dirs = {}, {}
        for _, item in ipairs(items) do
            local item_path = full_path .. "/" .. item
            local info = NFS.getInfo(item_path)
            if info then
                if info.type == 'file' and item:match("%.lua$") then
                    table.insert(files, item)
                elseif info.type == 'directory' or info.type == 'symlink' then
                    table.insert(dirs, item)
                end
            end
        end

        -- Load files first
        for _, filename in ipairs(files) do
            -- Check exclusion patterns
            local excluded = false
            for _, pattern in ipairs(options.exclude_patterns) do
                if filename == pattern or string.match(filename, pattern) then
                    excluded = true
                    break
                end
            end

            if not excluded then
                local file_relative_path = current_path .. "/" .. filename
                local chunk = SMODS.load_file(file_relative_path, mod_id)

                if chunk then
                    local success, err = pcall(chunk)
                    if success then
                        loaded_count.count = loaded_count.count + 1
                    else
                        local msg = string.format("Error executing %s: %s", file_relative_path, err)
                        if options.on_error == "throw" then
                            error(msg)
                        elseif options.on_error == "log" then
                            RIOSODU_SHARED.utils.sendWarnMessage(msg)
                        end
                    end
                else
                    local msg = string.format("Failed to load %s", file_relative_path)
                    if options.on_error == "throw" then
                        error(msg)
                    elseif options.on_error == "log" then
                        RIOSODU_SHARED.utils.sendWarnMessage(msg)
                    end
                end
            end
        end

        -- Recurse into subdirectories
        for _, dirname in ipairs(dirs) do
            RIOSODU_SHARED._walk_and_load(
                mod_id,
                current_path .. "/" .. dirname,
                depth + 1,
                options,
                loaded_count
            )
        end
    end

    -- Initialize hooks table
    RIOSODU_SHARED.hooks = {
        on_game_start = {},
        on_localization_reload = {}
    }

    -- Function to register hooks
    function RIOSODU_SHARED.register_hook(event_name, func)
        if RIOSODU_SHARED.hooks[event_name] then
            table.insert(RIOSODU_SHARED.hooks[event_name], func)
        end
    end

    -- Set up event to run hooks when game reaches main menu
    G.E_MANAGER:add_event(Event({
        blocking = false,
        blockable = false,
        func = function()
            if G.STAGE == G.STAGES.MAIN_MENU then
                for _, hook in ipairs(RIOSODU_SHARED.hooks.on_game_start) do
                    hook()
                    print("Running hook on_game_start")
                end
                return true
            end
            return false
        end
    }))

    include('overrides.lua')

    local function ensure_interest_properties(game_obj)
        game_obj.interest_base = 5
        return game_obj
    end
    RIOSODU_SHARED.utils.override_game_obj(ensure_interest_properties)

    print(string.format("[RIOSODU_SHARED] v%s initialization complete (bootstrapped by mod: %s)", RIOSODU_SHARED.version, host_id))
end

-- Initialize when the first mod loads this file
riosodu_shared_init()
