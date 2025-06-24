

--- @class QOL_BUNDLE.Config
--- @field joker_max_enabled boolean Enable/disable increased joker slots
--- @field joker_max_value number Number of joker slots when enabled
--- @field wildcard_fix_enabled boolean Enable/disable wildcard and blurred joker fixes
--- @field wheel_of_fortune_enabled boolean Enable/disable Wheel of Fortune change
--- @field wheel_of_fortune_value number Wheel of Fortune extra value (1-4)
--- @field eight_ball_joker_enabled boolean Enable/disable 8 Ball Joker chance modification
--- @field eight_ball_joker_value number 8 Ball Joker extra value (1-4)
--- @field unweighted_editions_enabled boolean Enable/disable unweighted base editions (foil, holo, poly)
--- @field hit_the_road_joker_enabled boolean Enable/disable reworked Hit the Road Joker
return {
  joker_max_enabled = true,         -- Enable/disable increased joker slots
  joker_max_value = 3,              -- Number of joker slots when enabled

  hit_the_road_joker_enabled = true, -- Enable/disable reworked Hit the Road Joker

  wildcard_fix_enabled = true,      -- Enable/disable wildcard and blurred joker fixes

  wheel_of_fortune_enabled = true,  -- Enable/disable Wheel of Fortune change
  wheel_of_fortune_value = 3,       -- Wheel of Fortune extra value (1-4)

  eight_ball_joker_enabled = true,  -- Enable/disable 8 Ball Joker chance modification
  eight_ball_joker_value = 4,       -- 8 Ball Joker extra value (1-4)

  unweighted_editions_enabled = false -- Enable/disable unweighted base editions (foil, holo, poly)
}
