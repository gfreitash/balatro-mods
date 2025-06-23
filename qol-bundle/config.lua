

--- @class QOL_BUNDLE.Config
--- @field joker_max_enabled boolean Enable/disable increased joker slots
--- @field joker_max_value number Number of joker slots when enabled
--- @field wildcard_fix_enabled boolean Enable/disable wildcard and blurred joker fixes
--- @field wheel_of_fortune_enabled boolean Enable/disable Wheel of Fortune change
--- @field wheel_of_fortune_value number Wheel of Fortune extra value (1-4)
--- @field unweighted_editions_enabled boolean Enable/disable unweighted base editions (foil, holo, poly)
return {
  joker_max_enabled = true,         -- Enable/disable increased joker slots
  joker_max_value = 3,              -- Number of joker slots when enabled

  wildcard_fix_enabled = true,      -- Enable/disable wildcard and blurred joker fixes

  wheel_of_fortune_enabled = true,  -- Enable/disable Wheel of Fortune change
  wheel_of_fortune_value = 3,       -- Wheel of Fortune extra value (1-4)

  unweighted_editions_enabled = false -- Enable/disable unweighted base editions (foil, holo, poly)
}
