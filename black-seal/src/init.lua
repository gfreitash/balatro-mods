---@diagnostic disable: duplicate-set-field

-- src/init.lua

-- mod globals
--- @class BSM
--- @field mod_id string The ID of the mod
--- @field mod Mod The mod object from SMODS
--- @field config BSM.Config The mod's configuration loaded from config.lua
--- @field state table A table to hold the mod's runtime state
--- @field utils table A table for utility functions
--- @field original table A table for storing original functions or values before overrides (no longer needed for poll_seal)
--- @field debug table A table for debug-specific functions/data
--- @field UI table A table for UI related functions/definitions
--- @field include fun(filename: string): nil A function to include other Lua files from the mod directory
--- @field black_seal_id string The base key for the Black Seal ('Black')
--- @field black_seal_id_full string The full key for the Black Seal ('blac_Black')
BSM = {} ---@type BSM


-- Initialize the mod
BSM.init = function(self)
  -- initialize globals/subtables
  self.state = {}
  self.utils = {}
  self.original = {} -- Table to store original functions or values before overrides
  self.debug = {}    -- Namespace for debug functions
  self.UI = {}       -- Namespace for UI related functions/definitions

  -- Link to the SMODS mod object and its config
  self.mod = SMODS.current_mod
  self.mod_id = self.mod.id
  self.config = self.mod.config -- Link config for easy access

  -- Define the include helper function
  ---@param filename string
  function self.include(filename)
    -- Load the file relative to the mod's directory
    local full_path = filename
    local mod_chunk = SMODS.load_file(full_path, self.mod_id)
    if mod_chunk then
      mod_chunk()
    end
  end
end

-- Run the initialization function
BSM:init()
-- Include other core modules
BSM.include("src/debug.lua") -- Includes Debug keybinds
BSM.include("src/main.lua") -- Includes Seal definition & initial weight setting
BSM.include("src/callbacks.lua") -- Functions for callbacks and events
BSM.include("src/overrides.lua") -- Includes the overrides for original functions
-- UI components moved to common mod via manifest dependency
BSM.include("src/ui/tabs.lua") -- Includes UI definitions

-- --- SMODS Hooks ---

SMODS.current_mod.config_tab = function() return BSM.UI.createConfigTabDefinition() end
SMODS.current_mod.debug_info = function(self)
  local info = {
    ["Black Seal Spawn Percentage"] = tostring(BSM.config.black_seal_percentage) .. "%",
    ["Debug Settings"] = "Managed by Riosodu Commons mod."
  }
  if RIOSODU_SHARED.config and RIOSODU_SHARED.config.debug_features_enabled then
    info["Black Seal Debug Keybinds"] = "F9 (Apply Seal), F10 (Test Weights), J (Add Joker), K (Open Spectral)"
  end
  return info
end

RIOSODU_SHARED.utils.sendDebugMessage("Initialization complete.")
