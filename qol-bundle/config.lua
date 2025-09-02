

--- @class QOL_BUNDLE.Config
--- @field joker_max_enabled boolean Enable/disable increased joker slots
--- @field joker_max_value number Number of joker slots when enabled
--- @field wildcard_fix_enabled boolean Enable/disable wildcard and blurred joker fixes
--- @field wheel_of_fortune_enabled boolean Enable/disable Wheel of Fortune change
--- @field wheel_of_fortune_value number Wheel of Fortune extra value (1-4)
--- @field eight_ball_joker_enabled boolean Enable/disable 8 Ball Joker chance modification
--- @field eight_ball_joker_value number 8 Ball Joker extra value (1-4)
--- @field unweighted_editions_enabled boolean Enable/disable unweighted base editions (foil, holo, poly)
--- @field flower_pot_wildcard_enabled boolean Enable/disable Flower Pot wildcard enhancement dependency
--- @field hit_the_road_joker_enabled boolean Enable/disable reworked Hit the Road Joker
--- @field square_joker_enabled boolean Enable/disable Square Joker modification
--- @field baron_uncommon_enabled boolean Enable/disable making Baron joker Uncommon with cheaper price
--- @field mime_rare_enabled boolean Enable/disable making Mime joker Rare with higher price
--- @field satellite_joker_enabled boolean Enable/disable Satellite Joker poker hand level modification
--- @field sigil_control_enabled boolean Enable/disable controlled Sigil spectral card using selected card's suit
--- @field ouija_control_enabled boolean Enable/disable controlled Ouija spectral card using selected card's rank
--- @field loyalty_card_rounds_enabled boolean Enable/disable Loyalty Card based on rounds instead of hands
--- @field splash_joker_retrigger_enabled boolean Enable/disable Splash Joker retriggering random scoring card
--- @field ceremonial_dagger_common_enabled boolean Enable/disable making Ceremonial Dagger Common with cheaper price
--- @field mail_in_rebate_uncommon_enabled boolean Enable/disable making Mail-In Rebate joker Uncommon
--- @field fortune_teller_cheaper_enabled boolean Enable/disable making Fortune Teller cheaper
--- @field erosion_xmult_enabled boolean Enable/disable Erosion giving 0.2X mult per card below starting amount
--- @field interest_on_skip_enabled boolean Enable/disable gaining interest when skipping blinds
return {
  joker_max_enabled = true,         -- Enable/disable increased joker slots
  joker_max_value = 3,              -- Number of joker slots when enabled

  hit_the_road_joker_enabled = true, -- Enable/disable reworked Hit the Road Joker
  square_joker_enabled = true,      -- Enable/disable Square Joker modification

  wildcard_fix_enabled = true,      -- Enable/disable wildcard and blurred joker fixes

  wheel_of_fortune_enabled = true,  -- Enable/disable Wheel of Fortune change
  wheel_of_fortune_value = 3,       -- Wheel of Fortune extra value (1-4)

  eight_ball_joker_enabled = true,  -- Enable/disable 8 Ball Joker chance modification
  eight_ball_joker_value = 4,       -- 8 Ball Joker extra value (1-4)

  unweighted_editions_enabled = false, -- Enable/disable unweighted base editions (foil, holo, poly)

  flower_pot_wildcard_enabled = true, -- Enable/disable Flower Pot wildcard enhancement dependency

  baron_uncommon_enabled = true, -- Enable/disable making Baron joker Uncommon with cheaper price
  mime_rare_enabled = true,      -- Enable/disable making Mime joker Rare with higher price

  nerf_photochad_enabled = true, -- Enable/disable Nerf Photochad (Photograph and Hanging Chad are uncommon)

  satellite_joker_enabled = true, -- Enable/disable Satellite Joker poker hand level modification

  sigil_control_enabled = true,   -- Enable/disable controlled Sigil spectral card using selected card's suit
  ouija_control_enabled = true,    -- Enable/disable controlled Ouija spectral card using selected card's rank

  loyalty_card_rounds_enabled = true, -- Enable/disable Loyalty Card based on rounds instead of hands

  splash_joker_retrigger_enabled = true, -- Enable/disable Splash Joker retriggering random scoring card

  ceremonial_dagger_common_enabled = true, -- Enable/disable making Ceremonial Dagger Common with cheaper price

  mail_in_rebate_uncommon_enabled = true, -- Enable/disable making Mail-In Rebate joker Uncommon

  fortune_teller_cheaper_enabled = true, -- Enable/disable making Fortune Teller cheaper

  erosion_xmult_enabled = true, -- Enable/disable Erosion giving 0.2X mult per card below starting amount

  interest_on_skip_enabled = true, -- Enable/disable gaining interest when skipping blinds
}
