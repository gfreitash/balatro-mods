-- Familiar/Grim/Incantation rework: the Enhanced cards they create also have a
-- chance to come with a Seal, and with a paper clip when Paperback is loaded.
function QOL_BUNDLE.funcs.get_ownership_spectral_enhanced()
    if not QOL_BUNDLE.config.spectral_seal_clip_enabled then
        return
    end

    local random_destroy = function(used_tarot)
        local destroyed_cards = {}
        destroyed_cards[#destroyed_cards + 1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                used_tarot:juice_up(0.3, 0.5)
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                for i = #destroyed_cards, 1, -1 do
                    local card = destroyed_cards[i]
                    if SMODS.shatters(card) then
                        card:shatter()
                    else
                        card:start_dissolve(nil, i ~= #destroyed_cards)
                    end
                end
                return true
            end
        }))
        return destroyed_cards
    end

    local pick_rank = {
        grim = function()
            return 'A', pseudorandom_element(SMODS.Suits, pseudoseed('grim_create')).card_key
        end,
        familiar = function()
            local faces = {}
            for _, v in ipairs(SMODS.Rank.obj_buffer) do
                local r = SMODS.Ranks[v]
                if r.face then table.insert(faces, r) end
            end
            return pseudorandom_element(faces, pseudoseed('familiar_create')).card_key,
                pseudorandom_element(SMODS.Suits, pseudoseed('familiar_create')).card_key
        end,
        incantation = function()
            local numbers = {}
            for _, v in ipairs(SMODS.Rank.obj_buffer) do
                local r = SMODS.Ranks[v]
                if v ~= 'Ace' and not r.face then table.insert(numbers, r) end
            end
            return pseudorandom_element(numbers, pseudoseed('incantation_create')).card_key,
                pseudorandom_element(SMODS.Suits, pseudoseed('incantation_create')).card_key
        end,
    }

    local make_use = function(pick)
        return function(self, card, area, copier)
            local used_tarot = copier or card
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, card.ability.extra do
                        local _rank, _suit = pick()
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if not v.overrides_base_rank then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        cards[i] = create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                        QOL_BUNDLE.utils.try_apply_seal(cards[i], 'qolb_' .. self.key .. '_seal')
                        QOL_BUNDLE.utils.try_apply_clip(cards[i], 'qolb_' .. self.key .. '_clip')
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            SMODS.calculate_context({ remove_playing_cards = true, removed = destroyed_cards })
        end
    end

    QOL_BUNDLE.state.spectral_familiar = SMODS.Consumable:take_ownership('c_familiar', {
        use = make_use(pick_rank.familiar)
    })
    QOL_BUNDLE.state.spectral_grim = SMODS.Consumable:take_ownership('c_grim', {
        use = make_use(pick_rank.grim)
    })
    QOL_BUNDLE.state.spectral_incantation = SMODS.Consumable:take_ownership('c_incantation', {
        use = make_use(pick_rank.incantation)
    })

    local apply_localization = function()
        local variants = {
            { key = 'c_familiar', upgraded = PB_UTIL and 'c_familiar_upgraded_paperback' or 'c_familiar_upgraded' },
            { key = 'c_grim', upgraded = PB_UTIL and 'c_grim_upgraded_paperback' or 'c_grim_upgraded' },
            { key = 'c_incantation', upgraded = PB_UTIL and 'c_incantation_upgraded_paperback' or 'c_incantation_upgraded' },
        }
        for _, v in ipairs(variants) do
            G.localization.descriptions.Spectral[v.key].text = localize(v.upgraded)
        end
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_spectral_enhanced()
