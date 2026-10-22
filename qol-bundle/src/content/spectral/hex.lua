-- Override Hex: still adds Polychrome to a random Joker, but instead of
-- destroying the others it rolls one random sticker for that same Joker.
-- Vanilla compat rules apply (no Perishable on Eternal, etc.).
function QOL_BUNDLE.funcs.get_ownership_spectral_hex()
    if not QOL_BUNDLE.config.hex_rework_enabled then
        return
    end

    -- Stickers that can legally be applied to this card right now, using the
    -- vanilla setters' own compatibility rules for the base game stickers.
    local function sticker_candidates(joker)
        local out = {}
        for _, key in ipairs(SMODS.Sticker.obj_buffer) do
            if key ~= 'pinned' and not joker.ability[key] then
                local ok = true
                if key == 'eternal' then
                    ok = joker.config.center.eternal_compat and not joker.ability.perishable
                elseif key == 'perishable' then
                    ok = joker.config.center.perishable_compat and not joker.ability.eternal
                end
                if ok then
                    out[#out + 1] = key
                end
            end
        end
        return out
    end

    local function apply_sticker(joker, key)
        if key == 'eternal' then
            joker:set_eternal(true)
        elseif key == 'perishable' then
            joker:set_perishable(true)
        elseif key == 'rental' then
            joker:set_rental(true)
        else
            joker:add_sticker(key, true)
        end
    end

    QOL_BUNDLE.state.hex = SMODS.Consumable:take_ownership('c_hex', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            local pool = {}
            for _, joker in ipairs(G.jokers.cards) do
                if not joker.edition then
                    pool[#pool + 1] = joker
                end
            end
            if #pool == 0 then
                return
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    local target = pseudorandom_element(pool, pseudoseed('hex'))
                    if not target then
                        return true
                    end

                    target:set_edition({ polychrome = true }, true)
                    check_for_unlock({ type = 'have_edition' })

                    local candidates = sticker_candidates(target)
                    if #candidates > 0 then
                        local sticker_key = pseudorandom_element(candidates, pseudoseed('hex_sticker'))
                        if sticker_key then
                            apply_sticker(target, sticker_key)
                        end
                    end

                    used_tarot:juice_up(0.3, 0.5)
                    return true
                end
            }))
            delay(0.5)
        end
    })

    local apply_localization = function()
        local loc = localize('c_hex_original')
        if QOL_BUNDLE.config.hex_rework_enabled then
            loc = localize('c_hex_modified')
        end
        G.localization.descriptions.Spectral.c_hex.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_spectral_hex()
