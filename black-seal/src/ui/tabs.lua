-- src/ui/tabs.lua

BSM.utils.sendDebugMessage("UI tabs module loading...")

-- --- UI Definition for the Config Tab ---
--- comment
--- @return UIBox The UI definition for the config tab
function BSM.UI.createConfigTabDefinition()
  return {
    n = G.UIT.ROOT,
    config = {
      align = "cm",
      colour = G.C.BLACK,
      r = 0.1,
      minw = 8,
    },
    nodes = { {
      n = G.UIT.C,
      config = {
        align = "cm",
        padding = 0.2,
      },
      nodes = {
        BSM.UI.create_option_box({
          BSM.UI.create_option_slider({
            ref_table = BSM.config,
            ref_value = "black_seal_percentage",
            label = "Black Seal Spawn Percentage",
            info = {
              "Percentage chance (%) for a black seal to be picked randomly.",
              "0% = Never spawn; 100% = Only black seals spawn.",
              string.format("Equal chance with other seals: %.0f%%.", 100 / BSM.utils.seal_count()),
            },
            min = 0,
            max = 100,
            step = 1,
            round = true, -- Ensure rounding
            minw = 2.5,   -- Give slider some width
            callback = 'bsm_calculate_and_set_seal_weights',
          })
        }),
        BSM.UI.create_option_box({
          BSM.UI.create_option_toggle({
            ref_table = BSM.config,
            ref_value = "override_ectoplasm_effect",
            label = "Override Ectoplasm Effect",
            info = {
              "Ectoplasm adds a black seal to a card instead.",
            },
            inactive_colour = G.C.WHITE,
            active_colour = G.C.BLUE,
            callback = function()
              BSM.utils.sendDebugMessage("Ectoplasm override toggled.")
              BSM.utils.update_ectoplasm_text()
              SMODS.save_mod_config(BSM.mod)
            end,
          })
        }),
        BSM.UI.create_option_box({
          BSM.UI.create_option_toggle({
            ref_table = BSM.config,
            ref_value = "ectoplasm_override_reduces_hand",
            label = "Ectoplasm Reduces Hand Size",
            info = {
              "If ectoplasm should reduce hand size",
            },
            inactive_colour = G.C.WHITE,
            active_colour = G.C.BLUE,
            callback = function()
              BSM.utils.sendDebugMessage("Ectoplasm hand size reduction toggled.")
              BSM.utils.update_ectoplasm_text()
              SMODS.save_mod_config(BSM.mod)
            end,
          })
        }),
        BSM.UI.create_option_box({
          BSM.UI.create_option_toggle({
            ref_table = BSM.config,
            ref_value = "debug_logging_enabled",
            label = "Enable Debug Logging",
            info = "Logs detailed mod actions to the console.",
            inactive_colour = G.C.WHITE,
            active_colour = G.C.BLUE,
            callback = function()
              BSM.utils.sendDebugMessage("Debug logging toggled.")
              SMODS.save_mod_config(BSM.mod)
            end,
          })
        }),
        BSM.UI.create_option_box({
          BSM.UI.create_option_toggle({
            ref_table = BSM.config,
            ref_value = "debug_keybinds_enabled",
            label = "Enable Debug Keybinds",
            info = "Enables testing keybinds. Requires restart.",
            inactive_colour = G.C.WHITE,
            active_colour = G.C.BLUE,
            callback = function()
              BSM.utils.sendDebugMessage("Debug keybinds toggled.")
              SMODS.save_mod_config(BSM.mod)
            end,
          })
        }),
      }

    } },
  }
end

BSM.utils.sendDebugMessage("UI tabs module loaded.")
