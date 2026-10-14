

--- @class QOL_BUNDLE.Config
--- @field joker_max_enabled boolean Enable/disable increased joker slots
--- @field joker_max_value number Number of joker slots when enabled
--- @field wildcard_fix_enabled boolean Enable/disable wildcard and blurred joker fixes
--- @field wheel_of_fortune_enabled boolean Enable/disable Wheel of Fortune change
--- @field wheel_of_fortune_value number Wheel of Fortune extra value (1-4)
--- @field eight_ball_joker_enabled boolean Enable/disable 8 Ball Joker chance modification
--- @field eight_ball_joker_value number 8 Ball Joker extra value (1-4)
--- @field space_joker_enabled boolean Enable/disable Space Joker chance modification
--- @field space_joker_value number Space Joker extra value (1-4)
--- @field steel_joker_enabled boolean Enable/disable Steel Joker buff
--- @field unweighted_editions_enabled boolean Enable/disable unweighted base editions (foil, holo, poly)
--- @field flower_pot_wildcard_enabled boolean Enable/disable Flower Pot wildcard enhancement dependency
--- @field hit_the_road_joker_enabled boolean Enable/disable reworked Hit the Road Joker
--- @field square_joker_enabled boolean Enable/disable Square Joker modification
--- @field baron_uncommon_enabled boolean Enable/disable making Baron joker Uncommon with cheaper price
--- @field mime_rare_enabled boolean Enable/disable making Mime joker Rare with higher price
--- @field nerf_hanging_chad_enabled boolean Enable/disable Nerf Hanging Chad (Hanging Chad is uncommon and more expensive)
--- @field satellite_joker_enabled boolean Enable/disable Satellite Joker poker hand level modification
--- @field sigil_control_enabled boolean Enable/disable controlled Sigil spectral card using selected card's suit
--- @field ouija_control_enabled boolean Enable/disable controlled Ouija spectral card using selected card's rank
--- @field spectral_seal_clip_enabled boolean Enable/disable Familiar/Grim/Incantation created cards having seals and paper clips
--- @field loyalty_card_scaling_enabled boolean Enable/disable Loyalty Card scaling mode instead of hands played
--- @field splash_joker_retrigger_enabled boolean Enable/disable Splash Joker retriggering random scoring card
--- @field ceremonial_dagger_common_enabled boolean Enable/disable making Ceremonial Dagger Common with cheaper price
--- @field mail_in_rebate_uncommon_enabled boolean Enable/disable making Mail-In Rebate joker Uncommon
--- @field fortune_teller_cheaper_enabled boolean Enable/disable making Fortune Teller cheaper
--- @field erosion_xmult_enabled boolean Enable/disable Erosion giving X mult per card below starting amount
--- @field interest_on_skip_enabled boolean Enable/disable gaining interest when skipping blinds
--- @field enhanced_magic_trick_enabled boolean Enable/disable enhanced Magic Trick voucher (all upgrades + seals)
--- @field new_illusion_enabled boolean Enable/disable new Illusion voucher (deck-based with reroll logic)
--- @field castle_checkered_enabled boolean Enable/disable Castle joker checkered deck enhancement
--- @field yorick_multiplier_enabled boolean Enable/disable Yorick multiplier modification
--- @field yorick_multiplier_value number Multiplier value per 23 cards discarded (default 1.5)
--- @field dna_uncommon_enabled boolean Enable/disable making DNA Uncommon with cheaper price
--- @field pareidolia_common_enabled boolean Enable/disable making Pareidolia Common with cheaper price
--- @field marble_joker_xchips_enabled boolean Enable/disable Marble Joker gaining X Chips per Stone card added to deck
--- @field stone_joker_mult_enabled boolean Enable/disable Stone Joker giving Mult per Stone card in deck
--- @field seance_rework_enabled boolean Enable/disable Seance triggering on secret hands and being Rare
--- @field caino_rework_enabled boolean Enable/disable Canio destroying scored face cards and scaling per destroyed face card
--- @field onyx_agate_enabled boolean Enable/disable Onyx Agate making Club cards permanently gain Mult when scored
return {
  joker_max_enabled = true,         -- Enable/disable increased joker slots
  joker_max_value = 3,              -- Number of joker slots when enabled

  hit_the_road_joker_enabled = true, -- Enable/disable reworked Hit the Road Joker
  square_joker_enabled = true,      -- Enable/disable Square Joker modification

  wildcard_fix_enabled = true,      -- Enable/disable wildcard and blurred joker fixes

  wheel_of_fortune_enabled = true,  -- Enable/disable Wheel of Fortune change
  wheel_of_fortune_value = 3,       -- Wheel of Fortune extra value (1-4)

  eight_ball_joker_enabled = true,  -- Enable/disable 8 Ball Joker chance modification
  eight_ball_joker_value = 3,       -- 8 Ball Joker extra value (1-4)

  space_joker_enabled = false,      -- Enable/disable Space Joker chance modification (beta)
  space_joker_value = 3,            -- Space Joker extra value (1-4)

  steel_joker_enabled = false,      -- Enable/disable Steel Joker buff (beta)

  unweighted_editions_enabled = false, -- Enable/disable unweighted base editions (foil, holo, poly)

  flower_pot_wildcard_enabled = true, -- Enable/disable Flower Pot wildcard enhancement dependency

  baron_uncommon_enabled = true, -- Enable/disable making Baron joker Uncommon with cheaper price
  mime_rare_enabled = true,      -- Enable/disable making Mime joker Rare with higher price

  dna_uncommon_enabled = false,   -- Enable/disable making DNA joker Uncommon with cheaper price (beta)
  pareidolia_common_enabled = false, -- Enable/disable making Pareidolia joker Common with cheaper price (beta)

  nerf_hanging_chad_enabled = true, -- Enable/disable Nerf Hanging Chad (Hanging Chad is uncommon and more expensive)

  satellite_joker_enabled = true, -- Enable/disable Satellite Joker poker hand level modification

  sigil_control_enabled = true,   -- Enable/disable controlled Sigil spectral card using selected card's suit
  ouija_control_enabled = true,    -- Enable/disable controlled Ouija spectral card using selected card's rank

  spectral_seal_clip_enabled = false, -- Enable/disable Familiar/Grim/Incantation created cards having seals and paper clips (beta)

  loyalty_card_scaling_enabled = false, -- Enable/disable Loyalty Card scaling mode (beta)

  splash_joker_retrigger_enabled = true, -- Enable/disable Splash Joker retriggering random scoring card

  ceremonial_dagger_common_enabled = true, -- Enable/disable making Ceremonial Dagger Common with cheaper price

  mail_in_rebate_uncommon_enabled = true, -- Enable/disable making Mail-In Rebate joker Uncommon

  fortune_teller_cheaper_enabled = true, -- Enable/disable making Fortune Teller cheaper

  erosion_xmult_enabled = true, -- Enable/disable Erosion giving 0.175X mult per card below starting amount

  interest_on_skip_enabled = true, -- Enable/disable gaining interest when skipping blinds

  -- Enhanced voucher features
  enhanced_magic_trick_enabled = true, -- Enable/disable enhanced Magic Trick voucher (all upgrades + seals)
  new_illusion_enabled = true, -- Enable/disable new Illusion voucher (deck-based with reroll logic)

  castle_checkered_enabled = true, -- Enable/disable Castle joker checkered deck enhancement

  marble_joker_xchips_enabled = true, -- Enable/disable Marble Joker gaining X Chips per Stone card added to deck
  stone_joker_mult_enabled = true, -- Enable/disable Stone Joker giving Mult per Stone card in deck

  -- Beta features (disabled by default, marked in the config menu)
  seance_rework_enabled = false, -- Enable/disable Seance triggering on secret hands and being Rare (beta)
  caino_rework_enabled = false,  -- Enable/disable Canio destroying scored face cards and scaling per destroyed face card (beta)
  onyx_agate_enabled = false,    -- Enable/disable Onyx Agate making Club cards permanently gain Mult when scored (beta)

  yorick_multiplier_enabled = true, -- Enable/disable Yorick multiplier modification
  yorick_multiplier_value = 1.5,   -- Multiplier value per 23 cards discarded (default 1.5)
}
