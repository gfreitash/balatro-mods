RIOSODU_SHARED.compat = RIOSODU_SHARED.compat or {}

RIOSODU_SHARED.compat.SMODS_GUI_DynamicUIManager_updateDynamicAreas = SMODS.GUI.DynamicUIManager.updateDynamicAreas
function SMODS.GUI.DynamicUIManager.updateDynamicAreas(uiDefinitions, config)
    base_conf = config or {
        offset = {x=0, y=0},
        align = 'cm',
    }

    for id, uiDefinition in pairs(uiDefinitions) do
        local dynamicArea = G.OVERLAY_MENU:get_UIE_by_ID(id)
        if dynamicArea and dynamicArea.config.object then
            cfg = SMODS.shallow_copy(base_conf)
            cfg.parent = dynamicArea

            dynamicArea.config.object:remove()
            dynamicArea.config.object = UIBox{
                definition = uiDefinition,
                config = cfg
            }
        end
    end
end

RIOSODU_SHARED.compat.SMODS_GUI_DynamicUIManager_initTab = SMODS.GUI.DynamicUIManager.initTab
function SMODS.GUI.DynamicUIManager.initTab(args)
    local updateFunctions = args.updateFunctions
    local staticPageDefinition = args.staticPageDefinition

    for _, updateFunction in pairs(updateFunctions) do
        G.E_MANAGER:add_event(Event({func = function()
            updateFunction{cycle_config = {}}
            return true
        end}))
    end

    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 8,
            align = "cm",
            colour = G.C.BLACK
        },
        nodes = {
            staticPageDefinition
        }
    }
end