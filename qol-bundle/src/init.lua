---@diagnostic disable: duplicate-set-field

-- src/init.lua

-- mod globals
--- @class QOL_BUNDLE
--- @field mod_id string The ID of the mod
--- @field mod Mod The mod object from SMODS
--- @field config QOL_BUNDLE.Config The mod's configuration loaded from config.lua
--- @field state table A table to hold the mod's runtime state
--- @field utils table A table for utility functions
--- @field original table A table for storing original functions or values before overrides
--- @field debug table A table for debug-specific functions/data
--- @field UI table A table for UI related functions/definitions
--- @field include fun(filename: string): nil A function to include other Lua files from the mod directory
QOL_BUNDLE = {} ---@type QOL_BUNDLE


-- Initialize the mod
QOL_BUNDLE.init = function(self)
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

  -- Initialize cycle config values based on loaded config
  -- wheel_of_fortune_value is 3 by default
  self.config.wheel_of_fortune_value = self.config.wheel_of_fortune_value or 4
  -- Since our values match their indices in the options array {1, 2, 3, 4},
  -- we can use the value directly as the index
  self.wheel_of_fortune_current_option = self.config.wheel_of_fortune_value
  self.wheel_of_fortune_current_option_val = self.config.wheel_of_fortune_value
end

-- Run the initialization function
QOL_BUNDLE:init()
-- Load config and re-acquire ownership
QOL_BUNDLE.config = SMODS.load_mod_config(QOL_BUNDLE.mod) or QOL_BUNDLE.config -- Ensure config is loaded before UI
QOL_BUNDLE.mod.config = QOL_BUNDLE.config -- Re-link config to mod object to maintain ownership
-- Include other core modules
RIOSODU_SHARED.include_mod_file(QOL_BUNDLE.mod_id, "src/main.lua") -- Main mod logic
RIOSODU_SHARED.include_mod_file(QOL_BUNDLE.mod_id, "src/overrides.lua") -- Function overrides
RIOSODU_SHARED.include_mod_file(QOL_BUNDLE.mod_id, "src/callbacks.lua") -- Callbacks
RIOSODU_SHARED.include_mod_file(QOL_BUNDLE.mod_id, "src/wheel_of_fortune.lua") -- Wheel of Fortune logic
RIOSODU_SHARED.include_mod_file(QOL_BUNDLE.mod_id, "src/ui/tabs.lua") -- UI definitions
RIOSODU_SHARED.include_mod_file(QOL_BUNDLE.mod_id, "src/debug.lua") -- Debug functions

-- SMODS Hooks
SMODS.current_mod.config_tab = function()
  return QOL_BUNDLE.UI.createConfigTabDefinition()
end


QOL_BUNDLE.debug.register_debug_keybinds()
RIOSODU_SHARED.utils.sendDebugMessage("QoL Bundle initialization complete.")
