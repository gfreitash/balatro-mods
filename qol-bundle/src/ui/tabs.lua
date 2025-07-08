-- QoL Bundle/src/ui/tabs.lua

QOL_BUNDLE.UI = QOL_BUNDLE.UI or {}

QOL_BUNDLE.UI.option_boxes_per_page = 4
QOL_BUNDLE.UI.last_viewed_config_page = 1

-- Helper function to get all config options, pre-wrapped in their intended option_boxes
function QOL_BUNDLE.UI.getAllConfigOptionBoxes()
    return {
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Joker Max Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'joker_max_enabled',
                label = G.localization.misc.dictionary.qolb_shop_size_label,
                info = G.localization.misc.dictionary.qolb_shop_size_info
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Wildcard Fix Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'wildcard_fix_enabled',
                label = G.localization.misc.dictionary.qolb_wildcard_fix_label,
                info = G.localization.misc.dictionary.qolb_wildcard_fix_info
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Wheel of Fortune Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'wheel_of_fortune_enabled',
                label = G.localization.misc.dictionary.qolb_wheel_fortune_label,
                info = G.localization.misc.dictionary.qolb_wheel_fortune_info
            }),
            create_option_cycle({
                colour = G.C.RED,
                options = {1, 2, 3, 4},
                opt_callback = 'qol_bundle_wheel_callback',
                current_option = QOL_BUNDLE.wheel_of_fortune_current_option,
                current_option_val = QOL_BUNDLE.wheel_of_fortune_current_option_val,
                scale = 0.75,
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- 8 Ball Joker Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'eight_ball_joker_enabled',
                label = G.localization.misc.dictionary.qolb_eight_ball_joker_label,
                info = G.localization.misc.dictionary.qolb_eight_ball_joker_info
            }),
            create_option_cycle({
                colour = G.C.RED,
                options = {1, 2, 3, 4},
                opt_callback = 'qol_bundle_eight_ball_joker_callback',
                current_option = QOL_BUNDLE.eight_ball_joker_current_option,
                current_option_val = QOL_BUNDLE.eight_ball_joker_current_option_val,
                scale = 0.75,
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Unweighted Editions Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'unweighted_editions_enabled',
                label = G.localization.misc.dictionary.qolb_unweighted_editions_label,
                info = G.localization.misc.dictionary.qolb_unweighted_editions_info
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Hit the Road Joker Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'hit_the_road_joker_enabled',
                label = G.localization.misc.dictionary.qolb_hit_the_road_joker_label,
                info = G.localization.misc.dictionary.qolb_hit_the_road_joker_info,
                callback = 'qol_bundle_update_hit_the_road_joker_localization'
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Square Joker Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'square_joker_enabled',
                label = G.localization.misc.dictionary.qolb_square_joker_label,
                info = G.localization.misc.dictionary.qolb_square_joker_info
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Nerf Photochad Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'nerf_photochad_enabled',
                label = G.localization.misc.dictionary.qolb_nerf_photochad_label,
                info = G.localization.misc.dictionary.qolb_nerf_photochad_info
            }),
        }),
    }
end

-- Static content for the config tab (includes the dynamic area placeholder and page selector)
function QOL_BUNDLE.UI.staticConfigTabContent()
    local allOptionBoxes = QOL_BUNDLE.UI.getAllConfigOptionBoxes()
    local totalPages = math.ceil(#allOptionBoxes / QOL_BUNDLE.UI.option_boxes_per_page)
    local pageOptions = {}
    for i = 1, totalPages do
        table.insert(pageOptions, (localize('k_page') .. ' ' .. tostring(i) .. "/" .. totalPages))
    end
    local currentPage = localize('k_page') .. ' ' .. QOL_BUNDLE.UI.last_viewed_config_page .. "/" .. totalPages


    return {
        n = G.UIT.ROOT,
        config = {
            align = "tm",
            colour = G.C.BLACK,
            r = 0.1,
            minh=8,
            padding=0.1
        },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "tm",
                    colour = G.C.BLACK,
                    padding = 0.05,
                },
                nodes = {
                    -- Dynamic content area for config options
                    {
                        n = G.UIT.R,
                        config = {
                            padding = 0.1,
                            r = 0.1,
                            minw = 10,
                            minh = 2 * QOL_BUNDLE.UI.option_boxes_per_page,
                            colour = G.C.BLACK,
                            align = "tm",
                        },
                        nodes = {
                            {
                                n=G.UIT.O,
                                config={
                                    id = 'qolConfigOptions',
                                    object = Moveable(),
                                }
                            },
                        }
                    },
                    -- Page selector (conditionally rendered)
                    totalPages > 1 and SMODS.GUI.createOptionSelector({
                        label = "",
                        scale = 0.8,
                        options = pageOptions,
                        opt_callback = 'qol_bundle_update_config_page',
                        no_pips = true,
                        current_option = currentPage,
                        config = { align = "cm", padding = 0.15 }
                    }) or nil
                }
            }
        }
    }
end

-- Dynamic content for the config tab (generates option boxes for a specific page)
function QOL_BUNDLE.UI.dynamicConfigTabContent(page)
    page = page or QOL_BUNDLE.UI.last_viewed_config_page
    QOL_BUNDLE.UI.last_viewed_config_page = page

    local allOptionBoxes = QOL_BUNDLE.UI.getAllConfigOptionBoxes()
    local startIndex = (page - 1) * QOL_BUNDLE.UI.option_boxes_per_page + 1
    local endIndex = math.min(startIndex + QOL_BUNDLE.UI.option_boxes_per_page - 1, #allOptionBoxes)
    local configNodes = {}

    for i = startIndex, endIndex do
        local optionBox = allOptionBoxes[i]
        if optionBox then
            table.insert(configNodes, optionBox)
        end
    end

    return {
        n = G.UIT.ROOT,
        config = {
            align = "cm",
            padding = 0.15,
            colour = G.C.BLACK,
        },
        nodes = configNodes
    }
end


G.FUNCS.qol_bundle_update_config_page = function(e)
    if not e or not e.cycle_config then return end
    SMODS.GUI.DynamicUIManager.updateDynamicAreas({
        ["qolConfigOptions"] = QOL_BUNDLE.UI.dynamicConfigTabContent(e.cycle_config.current_option)
    }, {
        offset = {x = 0.0, y = 0.0},
        align = "bm",
    })
end
