-- BlackSealMod/config.lua


--- @class BSM.Config
--- @field black_seal_percentage number
--- @field override_ectoplasm_effect boolean
--- @field ectoplasm_override_reduces_hand boolean
--- @field retrigger_black_seal boolean
--- @field keep_seals_in_hand boolean
return {
  black_seal_percentage = 10,               -- Chance for a Black Seal to spawn randomly relative to all other seals

  override_ectoplasm_effect = true,         -- Enable the Ectoplasm override effect
  ectoplasm_override_reduces_hand = true,   -- Enable hand size reduction on Ectoplasm override

  retrigger_black_seal = true,              -- Allow the Black Seal effect to trigger again when the card is retriggered
  keep_seals_in_hand = true,                -- Keep Black Seals on cards in hand when one is triggered
}
