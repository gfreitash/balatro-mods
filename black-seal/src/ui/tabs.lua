-- src/ui/tabs.lua

RIOSODU_SHARED.utils.sendDebugMessage("UI tabs module loading...")

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
        RIOSODU_SHARED.UIDEF.create_option_box({
          RIOSODU_SHARED.UIDEF.create_option_slider({
            ref_table = BSM.config,
            ref_value = "black_seal_percentage",
            label = localize('black_seal_spawn_percentage'),
            info = {
              localize('black_seal_spawn_percentage_info1'),
              localize('black_seal_spawn_percentage_info2'),
              string.format(localize('black_seal_spawn_percentage_info3'), 100 / BSM.utils.seal_count()),
            },
            min = 0,
            max = 100,
            step = 1,
            round = true, -- Ensure rounding
            minw = 2.5,   -- Give slider some width
            callback = 'bsm_calculate_and_set_seal_weights',
          })
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            RIOSODU_SHARED.UIDEF.create_option_toggle({
            ref_table = BSM.config,
            ref_value = "override_ectoplasm_effect",
            label = localize('override_ectoplasm_effect'),
            info = localize('override_ectoplasm_effect_info'),
            inactive_colour = G.C.WHITE,
            active_colour = G.C.BLUE,
            callback = function()
              RIOSODU_SHARED.utils.sendDebugMessage("Ectoplasm override toggled.")
              BSM.utils.update_ectoplasm_text()
              SMODS.save_mod_config(BSM.mod)
            end,
          })
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
          RIOSODU_SHARED.UIDEF.create_option_toggle({
            ref_table = BSM.config,
            ref_value = "ectoplasm_override_reduces_hand",
            label = localize('ectoplasm_override_reduces_hand'),
            info = localize('ectoplasm_override_reduces_hand_info'),
            inactive_colour = G.C.WHITE,
            active_colour = G.C.BLUE,
            callback = function()
              RIOSODU_SHARED.utils.sendDebugMessage("Ectoplasm hand size reduction toggled.")
              BSM.utils.update_ectoplasm_text()
              SMODS.save_mod_config(BSM.mod)
            end,
          })
        }),
      }

    } },
  }
end

RIOSODU_SHARED.utils.sendDebugMessage("UI tabs module loaded.")
