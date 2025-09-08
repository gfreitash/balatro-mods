-- QoL Bundle/src/ui/tabs.lua

QOL_BUNDLE.UI = QOL_BUNDLE.UI or {}

QOL_BUNDLE.UI.option_boxes_per_page = 3
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
                info = G.localization.misc.dictionary.qolb_shop_size_info,
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Wildcard Fix Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'wildcard_fix_enabled',
                label = G.localization.misc.dictionary.qolb_wildcard_fix_label,
                info = G.localization.misc.dictionary.qolb_wildcard_fix_info,
                requires_restart = true
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
            -- Nerf Hanging Chad Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'nerf_hanging_chad_enabled',
                label = G.localization.misc.dictionary.qolb_nerf_hanging_chad_label,
                info = G.localization.misc.dictionary.qolb_nerf_hanging_chad_info,
                requires_restart = true
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
                info = G.localization.misc.dictionary.qolb_unweighted_editions_info,
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Hit the Road Joker Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'hit_the_road_joker_enabled',
                label = G.localization.misc.dictionary.qolb_hit_the_road_joker_label,
                info = G.localization.misc.dictionary.qolb_hit_the_road_joker_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Square Joker Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'square_joker_enabled',
                label = G.localization.misc.dictionary.qolb_square_joker_label,
                info = G.localization.misc.dictionary.qolb_square_joker_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Flower Pot Wildcard Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'flower_pot_wildcard_enabled',
                label = G.localization.misc.dictionary.qolb_flower_pot_wildcard_label,
                info = G.localization.misc.dictionary.qolb_flower_pot_wildcard_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Baron Uncommon Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'baron_uncommon_enabled',
                label = G.localization.misc.dictionary.qolb_baron_uncommon_label,
                info = G.localization.misc.dictionary.qolb_baron_uncommon_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Mime Rare Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'mime_rare_enabled',
                label = G.localization.misc.dictionary.qolb_mime_rare_label,
                info = G.localization.misc.dictionary.qolb_mime_rare_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Ceremonial Dagger Common Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'ceremonial_dagger_common_enabled',
                label = G.localization.misc.dictionary.qolb_ceremonial_dagger_common_label,
                info = G.localization.misc.dictionary.qolb_ceremonial_dagger_common_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Mail-In Rebate Uncommon Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'mail_in_rebate_uncommon_enabled',
                label = G.localization.misc.dictionary.qolb_mail_in_rebate_uncommon_label,
                info = G.localization.misc.dictionary.qolb_mail_in_rebate_uncommon_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Fortune Teller Cheaper Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'fortune_teller_cheaper_enabled',
                label = G.localization.misc.dictionary.qolb_fortune_teller_cheaper_label,
                info = G.localization.misc.dictionary.qolb_fortune_teller_cheaper_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Erosion X Mult Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'erosion_xmult_enabled',
                label = G.localization.misc.dictionary.qolb_erosion_xmult_label,
                info = G.localization.misc.dictionary.qolb_erosion_xmult_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Sigil Control Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'sigil_control_enabled',
                label = G.localization.misc.dictionary.qolb_sigil_control_label,
                info = G.localization.misc.dictionary.qolb_sigil_control_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Ouija Control Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'ouija_control_enabled',
                label = G.localization.misc.dictionary.qolb_ouija_control_label,
                info = G.localization.misc.dictionary.qolb_ouija_control_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Splash Joker Retrigger Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'splash_joker_retrigger_enabled',
                label = G.localization.misc.dictionary.qolb_splash_joker_retrigger_label,
                info = G.localization.misc.dictionary.qolb_splash_joker_retrigger_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Interest on Skip Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'interest_on_skip_enabled',
                label = G.localization.misc.dictionary.qolb_interest_on_skip_label,
                info = G.localization.misc.dictionary.qolb_interest_on_skip_info,
                toggle_callback = QOL_BUNDLE.funcs.apply_interest_on_skip_override
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Castle Checkered Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'castle_checkered_enabled',
                label = G.localization.misc.dictionary.qolb_castle_checkered_label,
                info = G.localization.misc.dictionary.qolb_castle_checkered_info,
                requires_restart = true
            }),
        }),
        RIOSODU_SHARED.UIDEF.create_option_box({
            -- Yorick Multiplier Config
            RIOSODU_SHARED.UIDEF.create_option_toggle({
                ref_table = QOL_BUNDLE.config,
                ref_value = 'yorick_multiplier_enabled',
                label = G.localization.misc.dictionary.qolb_yorick_multiplier_label,
                info = G.localization.misc.dictionary.qolb_yorick_multiplier_info,
                requires_restart = true
            }),
            create_option_cycle({
                colour = G.C.XMULT,
                options = {1, 1.25, 1.5, 1.75, 2, 2.5, 3},
                opt_callback = 'qol_bundle_yorick_callback',
                current_option = QOL_BUNDLE.yorick_current_option,
                current_option_val = QOL_BUNDLE.yorick_current_option_val,
                scale = 0.75,
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
                            minh = 2.25 * QOL_BUNDLE.UI.option_boxes_per_page,
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
    RIOSODU_SHARED.UI.updateDynamicAreas({
        ["qolConfigOptions"] = QOL_BUNDLE.UI.dynamicConfigTabContent(e.cycle_config.current_option)
    }, {
        offset = {x = 0.0, y = 0.0},
        align = "bm",
    })
end
