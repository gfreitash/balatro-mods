RIOSODU_SHARED.original.init_localization = init_localization
RIOSODU_SHARED.original.Game_init_game_object = Game.init_game_object

function init_localization()
    local ret = RIOSODU_SHARED.original.init_localization()

    for _, hook in ipairs(RIOSODU_SHARED.hooks.on_localization_reload) do
        hook()
    end

    return ret
end


RIOSODU_SHARED._game_obj_callbacks = {}
---Register a callback to be called when the game object is initialized
---@param callback fun(game_obj: Game): Game
function RIOSODU_SHARED.utils.override_game_obj(callback)
    table.insert(RIOSODU_SHARED._game_obj_callbacks, callback)
end

function Game:init_game_object()
    local result = RIOSODU_SHARED.original.Game_init_game_object(self)

    for _, callback in ipairs(RIOSODU_SHARED._game_obj_callbacks) do
        local new_result = callback(result)
        result = new_result or result
    end
    return result
end