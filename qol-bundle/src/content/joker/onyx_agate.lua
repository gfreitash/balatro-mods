-- Override Onyx Agate: played Club cards permanently gain Mult when scored
function QOL_BUNDLE.funcs.get_ownership_joker_onyx_agate()
    if not QOL_BUNDLE.config.onyx_agate_enabled then
        return
    end

    QOL_BUNDLE.state.onyx_agate = SMODS.Joker:take_ownership('j_onyx_agate', {
        config = { extra = 3 },
        loc_vars = function(self, info_queue, center)
            return {
                vars = {
                    center.ability.extra  -- #1# - permanent Mult per scored Club
                }
            }
        end,
        calculate = function(self, card, context)
            if context.individual and context.cardarea == G.play
                and context.other_card:is_suit('Clubs') then
                -- Claim the context for blueprint passes too, so the vanilla
                -- flat Mult branch can never run: the perma gain is not copied
                if context.blueprint then
                    return {}
                end

                context.other_card.ability.perma_mult = (context.other_card.ability.perma_mult or 0) + card.ability.extra
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.MULT,
                    card = card
                }
            end
            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_onyx_agate_original')
        if QOL_BUNDLE.config.onyx_agate_enabled then
            loc = localize('j_onyx_agate_modified')
        end
        G.localization.descriptions.Joker.j_onyx_agate.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_onyx_agate()
