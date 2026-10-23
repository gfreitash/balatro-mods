-- Override Ankh: remove the vanilla run stickers (Eternal, Perishable and
-- Rental) from every Joker, then two random Jokers gain Eternal. Modded
-- stickers and Pinned are intentionally left alone: SMODS's remove_sticker
-- only clears the sticker flag, so generic removal would half-undo stickers
-- whose side effects this mod cannot know.
--
-- Tooltip colours for the three stickers, matching their badge colours.
-- loc_colour() first so G.ARGS.LOC_COLOURS is populated with the vanilla
-- palette before our keys are added.
loc_colour()
G.ARGS.LOC_COLOURS.qolb_eternal = G.C.ETERNAL
G.ARGS.LOC_COLOURS.qolb_perishable = G.C.PERISHABLE
G.ARGS.LOC_COLOURS.qolb_rental = G.C.RENTAL

local ANKH_STICKERS = { 'eternal', 'perishable', 'rental' }

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

                    -- Snapshot the row in display order (left to right).
                    local jokers = {}
                    for _, joker in ipairs(G.jokers.cards) do
                        jokers[#jokers + 1] = joker
                    end

                    -- Detect which Jokers actually have a sticker before removing
                    -- any, so only affected Jokers get the cleanup juice.
                    local affected = {}
                    for _, joker in ipairs(jokers) do
                        local has_sticker = false
                        for _, key in ipairs(ANKH_STICKERS) do
                            if joker.ability[key] then
                                has_sticker = true
                                break
                            end
                        end
                        if has_sticker then
                            affected[#affected + 1] = joker
                        end
                    end

                    -- Remove each Joker's stickers and juice it in order.
                    for _, joker in ipairs(affected) do
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.1,
                            func = function()
                                -- Capture side-effect state before the sticker
                                -- flags are cleared by remove_sticker.
                                local perishable_expired = joker.ability.perishable
                                    and (joker.ability.perish_tally or 0) <= 0
                                local had_rental = joker.ability.rental

                                for _, key in ipairs(ANKH_STICKERS) do
                                    joker:remove_sticker(key)
                                end

                                -- remove_sticker clears the flags but not the
                                -- vanilla side effects.
                                joker.ability.eternal = nil
                                joker.ability.perishable = nil
                                joker.ability.perish_tally = nil
                                joker.ability.rental = nil

                                if had_rental then
                                    joker:set_cost()
                                end
                                if perishable_expired and joker.debuff then
                                    SMODS.recalc_debuff(joker)
                                end

                                joker:juice_up(0.3, 0.5)
                                return true
                            end
                        }))
                    end

                    -- Let the cleanup read before revealing the new Eternal Jokers.
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.2,
                        func = function()
                            local pool = {}
                            for _, joker in ipairs(G.jokers.cards) do
                                if joker.config.center.eternal_compat and not joker.ability.eternal then
                                    pool[#pool + 1] = joker
                                end
                            end
                            pseudoshuffle(pool, pseudoseed('ankh_eternal'))

                            local targets = {}
                            for i = 1, math.min(2, #pool) do
                                targets[#targets + 1] = pool[i]
                            end

                            -- Juice the chosen Jokers left to right, regardless of
                            -- the order the shuffle picked them in.
                            local order = {}
                            for i, joker in ipairs(G.jokers.cards) do
                                order[joker] = i
                            end
                            table.sort(targets, function(a, b)
                                return (order[a] or 0) < (order[b] or 0)
                            end)

                            for i, joker in ipairs(targets) do
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'after',
                                    delay = i == 1 and 0 or 0.1,
                                    func = function()
                                        joker:set_eternal(true)
                                        joker:juice_up(0.3, 0.5)
                                        return true
                                    end
                                }))
                            end

                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                delay = 0.1,
                                func = function()
                                    used_tarot:juice_up(0.3, 0.5)
                                    return true
                                end
                            }))
                            return true
                        end
                    }))
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
