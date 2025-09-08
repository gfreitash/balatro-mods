return {
    misc = {
        dictionary={
            qolb_mod_name = 'QoL Bundle',
            qolb_mod_description = 'A collection of quality-of-life improvements for Balatro.',
            qolb_shop_size_label = 'Enable Increased Shop Size',
            qolb_shop_size_info = 'Increases shop size by 1',
            qolb_wildcard_fix_label = 'Enable Wildcard/Smeared Joker Fix',
            qolb_wildcard_fix_info = {
                'Prevents Wildcard/Smeared Joker from',
                'being debuffed by suit debuffs',
                'If Paperback is present,',
                'Smeared Joker will consider Crowns/Stars',

            },
            qolb_wheel_fortune_label = 'Enable Easier Wheel of Fortune',
            qolb_wheel_fortune_info = 'Adjust ease of Wheel of Fortune (1=100%, 4=25%).',
            qolb_unweighted_editions_label = 'Enable Unweighted Base Editions',
            qolb_unweighted_editions_info = 'Makes Foil, Holo, and Polychrome editions equally likely.',
            qolb_eight_ball_joker_label = 'Enable Configurable 8 Ball Joker',
            qolb_eight_ball_joker_info = 'Adjust chance of 8 Ball Joker spawning Tarot cards (1=100%, 4=25%).',
            qolb_hit_the_road_joker_label = 'Enable Hit the Road Joker Rework',
            qolb_hit_the_road_joker_info = {
                'When enabled, discarded Jacks are returned to the deck.',
                'The new effect is added alongside the original effect'
            },
            qolb_square_joker_label = 'Enable Square Joker Modification',
            qolb_square_joker_info = {
                'Square Joker gives +4 Chips,',
                'each scoring card has 1 in 2 chance for +4 more.',
                'Uncommon rarity.',
            },
            qolb_flower_pot_wildcard_label = 'Enable Flower Pot Wildcard Rework',
            qolb_flower_pot_wildcard_info = {
                'Flower Pot only appears in shop',
                'when Wildcard-enhanced cards exist in deck.',
                'Triggers if scoring hand has any Wildcard.'
            },
            qolb_baron_uncommon_label = 'Enable Baron Uncommon',
            qolb_baron_uncommon_info = {
                'Makes Baron joker Uncommon rarity',
                '(cost $5 instead of $8)'
            },
            qolb_mime_rare_label = 'Enable Mime Rare',
            qolb_mime_rare_info = {
                'Makes Mime joker Rare rarity',
                '(cost $6 instead of $5)'
            },
            qolb_ceremonial_dagger_common_label = 'Enable Ceremonial Dagger Common',
            qolb_ceremonial_dagger_common_info = {
                'Makes Ceremonial Dagger joker Common rarity',
                '(cost $3 instead of $6)'
            },
            qolb_mail_in_rebate_uncommon_label = 'Nerf Mail-In Rebate to Uncommon',
            qolb_mail_in_rebate_uncommon_info = {
                'Nerfs Mail-In Rebate joker to Uncommon rarity',
                '(was Common rarity - makes it rarer)'
            },
            qolb_fortune_teller_cheaper_label = 'Buff Fortune Teller Cost',
            qolb_fortune_teller_cheaper_info = {
                'Makes Fortune Teller joker cheaper',
                '(cost $4 instead of $6)'
            },
            qolb_erosion_xmult_label = 'Rework Erosion to X Mult',
            qolb_erosion_xmult_info = {
                'Changes Erosion from +4 Mult per card',
                'to X0.2 Mult per card below starting amount'
            },
            qolb_nerf_hanging_chad_label = 'Enable Nerf Hanging Chad',
            qolb_nerf_hanging_chad_info = 'Makes Hanging Chad joker Uncommon rarity and more expensive (cost $8 instead of $6).',
            qolb_satellite_joker_label = 'Enable Satellite Joker Rework',
            qolb_satellite_joker_info = {
                'Satellite now gives gold equal to half',
                'the highest poker hand level (rounded down)'
            },
            qolb_sigil_control_label = 'Enable Controlled Sigil',
            qolb_sigil_control_info = {
                'Sigil now requires selecting a card first.',
                'All cards in hand are converted to the',
                'selected card\'s suit instead of random suit.'
            },
            qolb_ouija_control_label = 'Enable Controlled Ouija',
            qolb_ouija_control_info = {
                'Ouija now requires selecting a card first.',
                'All cards in hand are converted to the',
                'selected card\'s rank instead of random rank.'
            },
            qolb_loyalty_card_rounds_label = 'Enable Loyalty Card Rounds Mode',
            qolb_loyalty_card_rounds_info = {
                'Loyalty Card triggers based on rounds (antes)',
                'instead of hands played for more predictable timing.'
            },
            qolb_splash_joker_retrigger_label = 'Enable Splash Joker Retrigger',
            qolb_splash_joker_retrigger_info = {
                'Splash Joker additionally retriggers',
                'a random scoring card'
            },
            qolb_interest_on_skip_label = 'Enable Interest on Skip',
            qolb_interest_on_skip_info = {
                'Gain interest when skipping blinds.',
                'Interest is calculated and awarded',
                'before obtaining the tag'
            },

            -- Original spectral texts (from base game)
            sigil_loc_text_original = {
                "Converts all cards",
                "in hand to a single",
                "random {C:attention}suit",
            },
            sigil_loc_text_controlled = {
                "Converts all cards in hand",
                "to the same {C:attention}suit{} as the",
                "{C:attention}1{} selected card"
            },
            ouija_loc_text_original = {
                "Converts all cards",
                "in hand to a single",
                "random {C:attention}rank",
                "{C:red}-1{} hand size",
            },
            ouija_loc_text_controlled = {
                "Converts all cards in hand",
                "to the same {C:attention}rank{} as the",
                "{C:attention}1{} selected card",
                "{C:red}-1{} hand size",
            },

            -- Original joker texts (from base game)
            j_hit_the_road_original = {
                "This Joker gains {X:mult,C:white} X#1# {} Mult",
                "for every {C:attention}Jack{}",
                "discarded this round",
                "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)"
            },
            j_hit_the_road_modified = {
                "This Joker gains {X:mult,C:white} X#1# {} Mult",
                "for every {C:attention}Jack{} discarded this round,",
                "and discarded {C:attention}Jacks{} are returned to deck.",
                "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)"
            },
            j_square_original = {
                "This Joker gains {C:chips}+#2#{} Chips",
                "if played hand has",
                "exactly {C:attention}4{} cards",
                "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"
            },
            j_square_modified = {
                "This Joker gains {C:chips}+#2#{} Chips",
                "if played hand has exactly {C:attention}4{} cards.",
                "Each scoring card has {C:green}#3# in #4#{} chance",
                "to give {C:chips}+#2#{} more Chips.",
                "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"
            },
            j_flower_pot_original = {
                "{X:mult,C:white} X#1# {} Mult if poker",
                "hand contains a",
                "{C:diamonds}Diamond{} card, {C:clubs}Club{} card,",
                "{C:hearts}Heart{} card, and {C:spades}Spade{} card"
            },
            j_flower_pot_modified = {
                "{X:mult,C:white} X#1# {} Mult if poker hand",
                "contains a {C:attention}Wild Card"
            },
            j_satellite_original = {
                "Earn {C:money}$#1#{} at end of",
                "round per unique {C:planet}Planet",
                "card used this run",
                "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
            },
            j_satellite_modified = {
                "Earn {C:money}$#1#{} at end of round for every",
                "{C:attention}2{} levels of your highest poker hand",
                "{C:inactive}(Currently {C:money}$#2#{C:inactive})"
            },
            j_loyalty_card_original = {
                "{X:red,C:white} X#1# {} Mult every",
                "{C:attention}#2#{} hands played",
                "{C:inactive}#3#",
            },
            j_loyalty_card_rounds = {
                "{X:red,C:white} X#1# {} Mult every",
                "{C:attention}#2#{} rounds",
                "{C:inactive}#3#",
            },
            j_splash_original = {
                "Every {C:attention}played card",
                "counts in scoring",
            },
            j_splash_retrigger = {
                "Every {C:attention}played card",
                "counts in scoring.",
                "{C:green}Random scoring card",
                "{C:green}is retriggered"
            },

            j_erosion_original = {
                "{C:red}+#1#{} Mult for each",
                "card below {C:attention}#2#{}",
                "in your full deck",
                "{C:inactive}(Currently {C:red}+#3#{C:inactive} Mult)",
            },
            j_erosion_xmult = {
                "{X:mult,C:white}X#1#{} Mult for each",
                "card below {C:attention}#2#{}",
                "in your full deck",
                "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
            },

            -- Enhanced voucher config labels
            qolb_enhanced_magic_trick_label = 'Enable Enhanced Magic Trick',
            qolb_enhanced_magic_trick_info = {
                'Magic Trick spawns playing cards with',
                'enhancements, editions, seals',
                'and clips (if Paperback is present)'
            },
            qolb_new_illusion_label = 'Enable New Illusion',
            qolb_new_illusion_info = {
                'Illusion spawns cards from your deck',
                'and rerolls their enhancements while',
                'preserving existing ones if reroll fails'
            },

            -- Original voucher texts (from base game)
            v_magic_trick_original = {
                "{C:attention}Playing cards{} can",
                "be purchased",
                "from the {C:attention}shop",
            },
            v_magic_trick_enhanced = {
                "{C:attention}Playing cards{} in shop",
                "may appear with {C:attention}enhancements{}, {C:dark_edition}editions{}, {C:attention}seals{},",
                "or {C:attention}paper clips{} (if Paperback is present)."
            },
            v_illusion_original = {
                "{C:attention}Playing cards{} in shop",
                "may have an {C:enhanced}Enhancement{},",
                "{C:dark_edition}Edition{}, and/or a {C:attention}Seal{}"
            },
            v_illusion_deck_based = {
                "{C:attention}Playing cards{} in shop are",
                "{C:attention}clones{} of cards in your {C:attention}deck{},",
                "and their upgrades can be {C:attention}rerolled{}."
            },

            -- Castle joker config
            qolb_castle_checkered_label = 'Enable Castle Checkered Enhancement',
            qolb_castle_checkered_info = {
                'Castle now counts either',
                'Clubs and Spades or Hearts and Diamonds.',
                'Become as reliable as in the checkered deck.'
            },
            qolb_yorick_multiplier_label = 'Enable Yorick Multiplier Configuration',
            qolb_yorick_multiplier_info = {
                'Configure how much X Mult Yorick gains',
                'per 23 cards discarded.',
                'Default: 1.5X',
            },

            -- Smeared joker texts (from base game)
            j_smeared_original = {
                "{C:hearts}Hearts{} and {C:diamonds}Diamonds",
                "count as the same suit,",
                "{C:spades}Spades{} and {C:clubs}Clubs",
                "count as the same suit",
            },
            j_smeared_paperback = {
                "{C:paperback_light_suit}Light suits{} count as",
                "the same suit,",
                "{C:paperback_dark_suit}Dark suits{} count as",
                "the same suit",
            },

            -- Castle joker texts (from base game)
            j_castle_original = {
                "This Joker gains {C:chips}+#1#{} Chips",
                "per discarded {V:1}#2#{} card,",
                "suit changes every round",
                "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips)",
            },
            j_castle_checkered = {
                "This Joker gains {C:chips}+#1#{} Chips per discarded",
                "{V:1}#2#{} or {V:2}#3#{} card, suit group changes every round",
                "{C:inactive}(Currently {C:chips}+#4#{C:inactive} Chips)",
            },
            j_castle_checkered_paperback = {
                "This Joker gains {C:chips}+#1#{} Chips",
                "per discarded {V:1}#2#{} cards,",
                "suit group changes every round",
                "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips)",
            },

            requires_restart = "Requires restart",
        },
    },
}
