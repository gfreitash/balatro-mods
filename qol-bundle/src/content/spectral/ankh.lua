-- Override Ankh: strip every sticker from every Joker, then two random
-- Jokers gain Eternal. Uses the vanilla setters, so Eternal compatibility and
-- the Perishable/Eternal exclusion are respected.
function QOL_BUNDLE.funcs.get_ownership_spectral_ankh()
    if not QOL_BUNDLE.config.ankh_rework_enabled then
        return
    end

    QOL_BUNDLE.state.ankh = SMODS.Consumable:take_ownership('c_ankh', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            if #G.jokers.cards == 0 then
                return
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    play_sound('timpani')

                    local jokers = {}
                    for _, joker in ipairs(G.jokers.cards) do
                        jokers[#jokers + 1] = joker
                    end

                    -- Remove vanilla and modded stickers alike.
                    for _, joker in ipairs(jokers) do
                        for key in pairs(SMODS.Stickers) do
                            joker:remove_sticker(key)
                        end
                    end

                    local pool = {}
                    for _, joker in ipairs(jokers) do
                        if joker.config.center.eternal_compat and not joker.ability.eternal then
                            pool[#pool + 1] = joker
                        end
                    end
                    pseudoshuffle(pool, pseudoseed('ankh_eternal'))
                    for i = 1, math.min(2, #pool) do
                        pool[i]:set_eternal(true)
                    end

                    used_tarot:juice_up(0.3, 0.5)
                    return true
                end
            }))
            delay(0.5)
        end
    })

    local apply_localization = function()
        local loc = localize('c_ankh_original')
        if QOL_BUNDLE.config.ankh_rework_enabled then
            loc = localize('c_ankh_modified')
        end
        G.localization.descriptions.Spectral.c_ankh.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_spectral_ankh()
