-- QoL Bundle/src/ui/tabs.lua

QOL_BUNDLE.UI = QOL_BUNDLE.UI or {}

function QOL_BUNDLE.UI.createConfigTabDefinition()
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
            }
        } }
    }
end
