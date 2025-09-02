RIOSODU_SHARED.original.init_localization = init_localization

function init_localization()
    local ret = RIOSODU_SHARED.original.init_localization()

    for _, hook in ipairs(RIOSODU_SHARED.hooks.on_localization_reload) do
        hook()
    end

    return ret
end