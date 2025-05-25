---@diagnostic disable: duplicate-set-field

-- Helper function for "Nope" feedback to reduce repetition
local function show_nope_feedback(used_tarot)
    G.E_MANAGER:add_event(
        Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                attention_text({ text = localize('k_nope_ex'), scale = 1.3, hold = 1.4, major = used_tarot })
                play_sound('tarot2', 1, 0.4)
                used_tarot:juice_up(0.3, 0.5)
                return true
            end,
        })
    )
    delay(0.6)
end

function BSM.utils.copy_table(stable)
    local output = {}
    for k, v in pairs(stable) do
        if type(v) == 'table' then  -- perform deep copy
            output[k] =BSM.utils.copy_table(v)
        else
            output[k] = v  -- primitive
        end
    end

    return output
end

-- Store the original functions before overriding
BSM.original.Card_use_consumeable = Card.use_consumeable
BSM.original.Card_can_use_consumeable = Card.can_use_consumeable

BSM.original.P_CENTERS_c_ectoplasm = G.P_CENTERS.c_ectoplasm
local ectoplasm = BSM.utils.copy_table(G.P_CENTERS.c_ectoplasm)
ectoplasm.config = {extra = BSM.black_seal_id_full, max_highlighted = 1}
G.P_CENTERS.c_ectoplasm = ectoplasm

-----------------------------------------------------------------------------
-- Overridden Card:use_consumeable
-----------------------------------------------------------------------------
function Card:use_consumeable(area, copier)
    -- Early return if not Ectoplasm OR if the override is disabled
    if not self.ability
        or self.ability.name ~= 'Ectoplasm'
        or not BSM.config.override_ectoplasm_effect
    then
        if self.ability and self.ability.name == 'Ectoplasm' then
            RIOSODU_SHARED.utils.sendDebugMessage("Using ORIGINAL Ectoplasm use_consumeable (Override Disabled)")
        end
        return BSM.original.Card_use_consumeable(self, area, copier)
    end

    -----------------------------------------------------
    -- Ectoplasm - BLACK SEAL OVERRIDE LOGIC
    -----------------------------------------------------
    RIOSODU_SHARED.utils.sendDebugMessage("Using OVERRIDDEN Ectoplasm use_consumeable (Black Seal)")

    -- Standard initial setup steps
    stop_use()
    if not copier then set_consumeable_usage(self) end

    -- Early return if debuffed
    if self.debuff then
        RIOSODU_SHARED.utils.sendDebugMessage("Ectoplasm Override: Cannot use (card is debuffed).")
        return nil -- Match original debuff return
    end

    local used_tarot = copier or self

    -- Early return if incorrect number of cards highlighted
    if not G.hand or #G.hand.highlighted ~= 1 then
        RIOSODU_SHARED.utils.sendDebugMessage("Ectoplasm Override: Cannot use (requires exactly 1 highlighted card).")
        show_nope_feedback(used_tarot)
        return
    end

    local target_card = G.hand.highlighted[1]

    -- Early return if target card is invalid or already sealed
    if not target_card or type(target_card.set_seal) ~= 'function'
    then
        RIOSODU_SHARED.utils.sendDebugMessage("Ectoplasm Override: Cannot apply seal (target invalid).")
        show_nope_feedback(used_tarot)
        return
    end

    -- --- All checks passed, proceed with applying the seal ---
    G.E_MANAGER:add_event(Event({
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
            RIOSODU_SHARED.utils.sendDebugMessage(
                "Ectoplasm Override: Applying Black Seal to target card."
            )
            target_card:set_seal(BSM.black_seal_id_full, nil, true)

            -- Conditionally apply hand size reduction
            if BSM.config.ectoplasm_override_reduces_hand then
                G.GAME.ecto_minus = G.GAME.ecto_minus or 1
                G.hand:change_size(-G.GAME.ecto_minus)
                G.GAME.ecto_minus = G.GAME.ecto_minus + 1
                RIOSODU_SHARED.utils.sendDebugMessage(
                    "Ectoplasm Override: Reduced hand size. Next reduction: "
                    .. G.GAME.ecto_minus
                )
            else
                RIOSODU_SHARED.utils.sendDebugMessage(
                    "Ectoplasm Override: Hand size reduction skipped (config)."
                )
            end
            return true
        end
    }))

    delay(0.5)
    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.2, func = function()
        G.hand:unhighlight_all(); return true
    end }))
end

-----------------------------------------------------------------------------
-- Overridden Card:can_use_consumeable
-----------------------------------------------------------------------------
function Card:can_use_consumeable(any_state, skip_check)
    -- Early return if not Ectoplasm OR if the override is disabled
    if not self.ability
        or self.ability.name ~= 'Ectoplasm'
        or not BSM.config.override_ectoplasm_effect
    then
        return BSM.original.Card_can_use_consumeable(self, any_state, skip_check)
    end

    -----------------------------------------------------
    -- Ectoplasm - BLACK SEAL OVERRIDE CHECK
    -----------------------------------------------------

    -- Early return if not actually a consumable
    if not self.ability.consumeable then return false end

    -- Early return if usage is blocked by game state/controller lock
    if not skip_check
        and ((G.play and #G.play.cards > 0)
            or (G.CONTROLLER.locked)
            or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
    then
        return false
    end

    -- Early return if game state doesn't allow usage (and not forced by any_state)
    if (
        G.STATE == G.STATES.HAND_PLAYED or
        G.STATE == G.STATES.DRAW_TO_HAND or
        G.STATE == G.STATES.PLAY_TAROT
    ) and not any_state
    then
        return false
    end

    -- Early return if a custom hook handles the check
    local obj = self.config.center
    if obj.can_use and type(obj.can_use) == 'function' then
        return obj:can_use(self)
    end

    if not (
            G.STATE == G.STATES.SELECTING_HAND
            or G.STATE == G.STATES.TAROT_PACK
            or G.STATE == G.STATES.SPECTRAL_PACK
            or G.STATE == G.STATES.PLANET_PACK
            or G.STATE == G.STATES.SMODS_BOOSTER_OPENED
        )
    then
        return false
    end

    if self.ability.consumeable.max_highlighted then
        if self.ability.consumeable.mod_num >= #G.hand.highlighted and #G.hand.highlighted >= (self.ability.consumeable.min_highlighted or 1) then
            return true
        end
    end
end

function BSM.utils.update_ectoplasm_text()
    local loc_text = {
        "Add {C:dark_edition}Negative{} to",
        "a random {C:attention}Joker,",
        "{C:red}-#1#{} hand size",
    }

    if BSM.config.ectoplasm_override_reduces_hand then
        loc_text[3] = "{C:red}-#1#{} hand size"
    else
        loc_text[3] = nil
    end

    if BSM.config.override_ectoplasm_effect then
        loc_text[4] = loc_text[3]
        loc_text[1] = "Add a {C:dark_edition}Black Seal{}"
        loc_text[2] = "to {C:attention}1{} selected"
        loc_text[3] = "card in your hand"
    end

    G.localization.descriptions.Spectral.c_ectoplasm.text = loc_text
end

BSM.utils.update_ectoplasm_text()
