-- Override Mail-In Rebate to make it Uncommon
function QOL_BUNDLE.funcs.get_ownership_joker_mail()
    if not QOL_BUNDLE.config.mail_in_rebate_uncommon_enabled then
        return
    end

    QOL_BUNDLE.state.mail_in_rebate = SMODS.Joker:take_ownership('j_mail', {
        rarity = 2, -- Uncommon (was 1 - Common)
        cost = 8,   -- Cheaper (was 4)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_mail()
