-- Override Mr. Bones: always prevents Death, but self-destructs and Cripples
-- the run (-1 Ante, money set to $0, -1 hand, -1 hand size, -1 discard).
function QOL_BUNDLE.funcs.get_ownership_joker_mr_bones()
    if not QOL_BUNDLE.config.mr_bones_rework_enabled then
        return
    end

    QOL_BUNDLE.state.mr_bones = SMODS.Joker:take_ownership('j_mr_bones', {
        cost = 10,
        calculate = function(self, card, context)
            if not context.game_over then
                return nil
            end

            G.E_MANAGER:add_event(Event({
                func = function()
                    G.hand_text_area.blind_chips:juice_up()
                    G.hand_text_area.game_chips:juice_up()
                    play_sound('tarot1')

                    -- Crippling penalties.
                    ease_dollars(-G.GAME.dollars, true)
                    ease_ante(-1)
                    G.GAME.round_resets.blind_ante = (G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante) - 1
                    G.GAME.round_resets.hands = G.GAME.round_resets.hands - 1
                    ease_hands_played(-1)
                    G.GAME.round_resets.discards = G.GAME.round_resets.discards - 1
                    ease_discard(-1)
                    G.hand:change_size(-1)

                    attention_text({
                        text = localize('k_crippled_ex'),
                        scale = 1,
                        hold = 1.4,
                        major = card,
                        backdrop_colour = G.C.RED,
                        align = 'cm'
                    })

                    card:start_dissolve()
                    return true
                end
            }))

            -- Claiming game_over suppresses the vanilla self-destruct branch.
            return {
                message = localize('k_saved_ex'),
                saved = true,
                colour = G.C.RED
            }
        end,
        loc_vars = function(self, info_queue, center)
            -- Makes the "Crippled" flavour readable as an extra tooltip.
            info_queue[#info_queue + 1] = { key = 'crippled', set = 'Other' }
            return {}
        end
    })

    local apply_localization = function()
        local loc = localize('j_mr_bones_original')
        if QOL_BUNDLE.config.mr_bones_rework_enabled then
            loc = localize('j_mr_bones_modified')
        end
        G.localization.descriptions.Joker.j_mr_bones.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_mr_bones()
