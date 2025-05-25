-- Common UI settings tab
function RIOSODU_SHARED.UI.createDebugSettingsTabDefinition()
  return {
    n = G.UIT.ROOT,
    config = {
      align = "cm",
      colour = G.C.BLACK,
      r = 0.1,
      minw = 8,
    },
    nodes = {
      {
        n = G.UIT.C,
        config = { align = "cm", padding = 0.2 },
        nodes = {
          RIOSODU_SHARED.UIDEF.create_option_box({
            RIOSODU_SHARED.UIDEF.create_option_toggle({
              ref_table = RIOSODU_SHARED.config,
              ref_value = "debug_logging_enabled",
              label = "Enable Debug Logging",
              info = "Toggle debug message logging across all mods",
              callback = function()
                SMODS.save_mod_config(SMODS.current_mod)
              end
            })
          }),
          RIOSODU_SHARED.UIDEF.create_option_box({
            RIOSODU_SHARED.UIDEF.create_option_toggle({
              ref_table = RIOSODU_SHARED.config,
              ref_value = "debug_features_enabled",
              label = "Enable Debug Features",
              info = "Toggle debug keybinds and experimental features",
              callback = function()
                SMODS.save_mod_config(SMODS.current_mod)
              end
            })
          })
        }
      }
    }
  }
end
