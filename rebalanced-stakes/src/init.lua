---@diagnostic disable: duplicate-set-field

-- src/init.lua

-- mod globals
--- @class RSM
--- @field mod_id string The ID of the mod
--- @field mod Mod The mod object from SMODS
--- @field config RSM.Config The mod's configuration loaded from config.lua
--- @field state table A table to hold the mod's runtime state
--- @field utils table A table for utility functions
--- @field original table A table for storing original functions or values before overrides
--- @field debug table A table for debug-specific functions/data
--- @field UI table A table for UI related functions/definitions
--- @field include fun(filename: string): nil A function to include other Lua files from the mod directory
RSM = {} ---@type RSM

-- Initialize the mod
RSM.init = function(self)
  -- initialize globals/subtables
  self.state = {}
  self.utils = {}
  self.original = {}
  self.debug = {}
  self.UI = {}

  -- Link to the SMODS mod object and its config
  self.mod = SMODS.current_mod
  self.mod_id = self.mod.id
  self.config = self.mod.config -- Link config for easy access

end

-- Run the initialization function
RSM:init()

-- Include other core modules
RIOSODU_SHARED.include_mod_file(RSM.mod_id, "src/main.lua") -- Includes the main logic
RIOSODU_SHARED.utils.sendDebugMessage("Rebalanced Stakes mod initialized", RSM.mod_id)