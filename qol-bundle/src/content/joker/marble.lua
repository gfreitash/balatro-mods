-- Override Marble Joker: keeps adding a Stone card at blind selection and also
-- gains X Chips for every Stone card added to the deck (from any source)
function QOL_BUNDLE.funcs.get_ownership_joker_marble()
    if not QOL_BUNDLE.config.marble_joker_xchips_enabled then
        return
    end

    local normalize_extra = function(card)
        -- Legacy saves may still hold the vanilla numeric extra
        if type(card.ability.extra) ~= 'table' then
            card.ability.extra = { xchips = 1 }
        elseif not card.ability.extra.xchips then
            card.ability.extra.xchips = 1
        end
    end

    QOL_BUNDLE.state.marble_joker = SMODS.Joker:take_ownership('j_marble', {
        config = { extra = { xchips = 1 } },
        loc_vars = function(self, info_queue, center)
            local extra = center.ability.extra
            if type(extra) ~= 'table' then extra = { xchips = 1 } end
            return {
                vars = {
                    extra.xchips  -- #1# - current X Chips
                }
            }
        end,
        calculate = function(self, card, context)
            normalize_extra(card)

            if context.playing_card_added and not context.blueprint then
                local stone_added = 0
                for _, added in ipairs(context.cards or {}) do
                    if added ~= true and SMODS.is_playing_card(added)
                        and added.config and added.config.center
                        and added.config.center.key == 'm_stone' then
                        stone_added = stone_added + 1
                    end
                end

                if stone_added > 0 then
                    card.ability.extra.xchips = card.ability.extra.xchips + 0.1 * stone_added
                    return {
                        message = localize{type = 'variable', key = 'a_xchips', vars = {card.ability.extra.xchips}},
                        colour = G.C.CHIPS
                    }
                end
                return {}
            end

            -- Never claim setting_blind: the vanilla Stone card creation must run
            if context.joker_main then
                if card.ability.extra.xchips > 1 then
                    return { x_chips = card.ability.extra.xchips }
                end
                return {}
            end

            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_marble_original')
        if QOL_BUNDLE.config.marble_joker_xchips_enabled then
            loc = localize('j_marble_modified')
        end
        G.localization.descriptions.Joker.j_marble.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_marble()
