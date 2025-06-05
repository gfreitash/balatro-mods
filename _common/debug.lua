-- Common debug system
RIOSODU_SHARED.debug = RIOSODU_SHARED.debug or {
  registered_keybinds = {}
}

function RIOSODU_SHARED.utils.sendDebugMessage(msg, mod_id)
  if RIOSODU_SHARED.config and RIOSODU_SHARED.config.debug_logging_enabled then
    local full_msg = (mod_id or 'riosodu_shared') .. ": " .. tostring(msg)
    if SMODS and SMODS.log then
      SMODS.log(full_msg)
    elseif G and G.log and G.log.debug then
      G.log.debug(full_msg)
    else
      print(full_msg)
    end
  end
end

function RIOSODU_SHARED.debug.register_keybind(mod_id, keybind_def)
  if RIOSODU_SHARED.config.debug_features_enabled then
    local kb = keybind_def
    kb.desc = kb.desc .. ' (' .. kb.key_pressed:upper() .. ')'
    SMODS.Keybind(kb)
    RIOSODU_SHARED.utils.sendDebugMessage(mod_id,
      "Registered debug keybind: " .. kb.name)
  end
end

RIOSODU_SHARED.debug.register_keybind('riosodu_shared', {
  key_pressed = 'f12',
  name = 'restart_game',
  desc = 'Restart Game',
  action = function() SMODS.restart_game() end
})
