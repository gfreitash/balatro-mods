-- BlackSealMod/config.lua


--- @class BSM.Config
--- @field black_seal_percentage number
--- @field override_ectoplasm_effect boolean
--- @field ectoplasm_override_reduces_hand boolean
--- @field debug_logging_enabled boolean
--- @field debug_features_enabled boolean
--- @field debug_apply_seal_key string
--- @field debug_test_weights_key string
--- @field debug_add_joker_key string
--- @field debug_open_spectral_pack_key string
return {
  black_seal_percentage = 10,               -- Chance for a Black Seal to spawn randomly relative to all other seals

  override_ectoplasm_effect = true,         -- Enable the Ectoplasm override effect
  ectoplasm_override_reduces_hand = true,   -- Enable hand size reduction on Ectoplasm override

  debug_logging_enabled = false,            -- Enable verbose debug messages in the log
  debug_features_enabled = false,           -- Enable debug keybinds and related features

  debug_apply_seal_key = "f9",              -- Key to apply Black Seal to hand
  debug_test_weights_key = "f10",           -- Key to test seal weights
  debug_add_joker_key = 'j',                -- Key to add a random Joker
  debug_open_spectral_pack_key = 'k',       -- Key to open the Spectral Pack
}
