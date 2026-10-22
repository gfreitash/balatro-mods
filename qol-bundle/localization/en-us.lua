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
            qolb_space_joker_label = 'Enable Configurable Space Joker',
            qolb_space_joker_info = 'Adjust chance of Space Joker upgrading the played poker hand (1=100%, 4=25%).',
            qolb_steel_joker_label = 'Enable Steel Joker Buff',
            qolb_steel_joker_info = 'Steel Joker gives X0.25 Mult per Steel Card (was X0.2).',
            qolb_hit_the_road_joker_label = 'Enable Hit the Road Joker Rework',
            qolb_hit_the_road_joker_info = {
                'When enabled, discarded Jacks are returned to the deck.',
                'The new effect is added alongside the original effect'
            },
            qolb_square_joker_label = 'Enable Square Joker Modification',
            qolb_square_joker_info = {
                'Square Joker gives +2 Chips,',
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
            qolb_dna_uncommon_label = 'Enable DNA Uncommon',
            qolb_dna_uncommon_info = {
                'Makes DNA joker Uncommon rarity',
                '(cost $6 instead of $8)'
            },
            qolb_pareidolia_common_label = 'Enable Pareidolia Common',
            qolb_pareidolia_common_info = {
                'Makes Pareidolia joker Common rarity',
                '(cost $4 instead of $5)'
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
                'to X0.175 Mult per card below starting amount'
            },
            qolb_nerf_hanging_chad_label = 'Enable Nerf Hanging Chad',
            qolb_nerf_hanging_chad_info = {
                'Makes Hanging Chad joker Uncommon rarity and',
                'more expensive (cost $8 instead of $6).'
            },
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
            qolb_loyalty_card_scaling_label = 'Enable Loyalty Card Scaling Mode',
            qolb_loyalty_card_scaling_info = {
                'Loyalty Card starts at X1 Mult, gains X0.5 Mult',
                'after finishing a blind, and redeems back to X2',
                'after finishing a blind at X4'
            },
            qolb_spectral_seal_clip_label = 'Spectral Created Cards Can Have Seals',
            qolb_spectral_seal_clip_info = {
                'Cards created by Familiar, Grim and Incantation',
                'have a chance to come with a Seal'
            },
            qolb_spectral_seal_clip_info_paperback = {
                'Cards created by Familiar, Grim and Incantation',
                'have a chance to come with a Seal',
                'or a paper clip (with Paperback)'
            },
            qolb_splash_joker_retrigger_label = 'Enable Splash Joker Retrigger',
            qolb_splash_joker_retrigger_info = {
                'Splash Joker additionally retriggers',
                'two random scoring cards'
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
                "and discarded {C:attention}Jacks{} are returned to deck",
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
                "if played hand has exactly {C:attention}4{} cards",
                "Each scoring card has {C:green}#3# in #4#{} chance",
                "to give {C:chips}+#5#{} more Chips",
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
            j_splash_original = {
                "Every {C:attention}played card",
                "counts in scoring",
            },
            j_splash_retrigger = {
                "Every {C:attention}played card",
                "counts in scoring",
                "{C:green}Retrigger two of them",
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

            -- Marble joker texts (from base game)
            j_marble_original = {
                "Adds one {C:attention}Stone{} card",
                "to deck when",
                "{C:attention}Blind{} is selected",
            },
            j_marble_modified = {
                "Adds one {C:attention}Stone{} card to deck when",
                "{C:attention}Blind{} is selected, and gains",
                "{X:chips,C:white}X0.1{} Chips for each {C:attention}Stone{} card",
                "added to deck",
                "{C:inactive}(Currently {X:chips,C:white}X#1#{C:inactive} Chips)",
            },

            -- Stone joker texts (from base game)
            j_stone_original = {
                "Gives {C:chips}+#1#{} Chips for",
                "each {C:attention}Stone Card",
                "in your {C:attention}full deck",
                "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
            },
            j_stone_modified = {
                "Gives {C:mult}+#1#{} Mult for",
                "each {C:attention}Stone Card",
                "in your {C:attention}full deck",
                "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
            },

            -- Seance joker texts (from base game)
            j_seance_original = {
                "If {C:attention}poker hand{} is a",
                "{C:attention}#1#{}, create a",
                "random {C:spectral}Spectral{} card",
                "{C:inactive}(Must have room)",
            },
            j_seance_modified = {
                "If {C:attention}poker hand{} is a",
                "{C:attention}Straight Flush{} or a {C:attention}secret hand{},",
                "create a random {C:spectral}Spectral{} card",
                "{C:inactive}(Must have room)",
            },

            -- Canio joker texts (from base game)
            j_caino_original = {
                "This Joker gains {X:mult,C:white} X#1# {} Mult",
                "when a {C:attention}face{} card",
                "is destroyed",
                "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
            },
            j_caino_modified = {
                "Destroys played {C:attention}face{} cards and",
                "gains {X:mult,C:white} X#1# {} Mult per destroyed",
                "{C:attention}face{} card",
                "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
            },

            -- Onyx Agate joker texts (from base game)
            j_onyx_agate_original = {
                "Played cards with",
                "{C:clubs}Club{} suit give",
                "{C:mult}+#1#{} Mult when scored",
            },
            j_onyx_agate_modified = {
                "Played cards with {C:clubs}Club{} suit",
                "permanently gain {C:mult}+#1#{} Mult",
                "when scored",
            },

            -- Familiar/Grim/Incantation texts (from base game)
            c_familiar_original = {
                "Destroy {C:attention}1{} random",
                "card in your hand, add",
                "{C:attention}#1#{} random {C:attention}Enhanced face",
                "{C:attention}cards{} to your hand",
            },
            c_familiar_upgraded = {
                "Destroy {C:attention}1{} random",
                "card in your hand, add",
                "{C:attention}#1#{} random {C:attention}Enhanced face",
                "{C:attention}cards{} to your hand",
                "{C:green}Chance{} to add a {C:attention}Seal",
            },
            c_familiar_upgraded_paperback = {
                "Destroy {C:attention}1{} random",
                "card in your hand, add",
                "{C:attention}#1#{} random {C:attention}Enhanced face",
                "{C:attention}cards{} to your hand",
                "{C:green}Chance{} to add a {C:attention}Seal{} or {C:attention}paper clip",
            },
            c_grim_original = {
                "Destroy {C:attention}1{} random",
                "card in your hand,",
                "add {C:attention}#1#{} random {C:attention}Enhanced",
                "{C:attention}Aces{} to your hand",
            },
            c_grim_upgraded = {
                "Destroy {C:attention}1{} random",
                "card in your hand,",
                "add {C:attention}#1#{} random {C:attention}Enhanced",
                "{C:attention}Aces{} to your hand",
                "{C:green}Chance{} to add a {C:attention}Seal",
            },
            c_grim_upgraded_paperback = {
                "Destroy {C:attention}1{} random",
                "card in your hand,",
                "add {C:attention}#1#{} random {C:attention}Enhanced",
                "{C:attention}Aces{} to your hand",
                "{C:green}Chance{} to add a {C:attention}Seal{} or {C:attention}paper clip",
            },
            c_incantation_original = {
                "Destroy {C:attention}1{} random",
                "card in your hand, add {C:attention}#1#",
                "random {C:attention}Enhanced numbered",
                "{C:attention}cards{} to your hand",
            },
            c_incantation_upgraded = {
                "Destroy {C:attention}1{} random",
                "card in your hand, add {C:attention}#1#",
                "random {C:attention}Enhanced numbered",
                "{C:attention}cards{} to your hand",
                "{C:green}Chance{} to add a {C:attention}Seal",
            },
            c_incantation_upgraded_paperback = {
                "Destroy {C:attention}1{} random",
                "card in your hand, add {C:attention}#1#",
                "random {C:attention}Enhanced numbered",
                "{C:attention}cards{} to your hand",
                "{C:green}Chance{} to add a {C:attention}Seal{} or {C:attention}paper clip",
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
                "may appear with {C:attention}enhancements{}, {C:dark_edition}editions{},",
                "and/or {C:attention}seals{}"
            },
            v_magic_trick_paperback = {
                "{C:attention}Playing cards{} in shop",
                "may appear with {C:attention}enhancements{}, {C:dark_edition}editions{},",
                "{C:attention}seals{}, and/or {C:attention}paper clips{}"
            },
            v_illusion_original = {
                "{C:attention}Playing cards{} in shop",
                "may have an {C:enhanced}Enhancement{},",
                "{C:dark_edition}Edition{}, and/or a {C:attention}Seal{}"
            },
            v_illusion_deck_based = {
                "{C:attention}Playing cards{} in shop are",
                "{C:attention}clones{} of cards in your {C:attention}deck{},",
                "and their upgrades can be {C:attention}rerolled{}"
            },
            v_planet_merchant_original = {
                "{C:planet}Planet{} cards appear",
                "{C:attention}#1#X{} more frequently",
                "in the shop",
            },
            v_planet_merchant_modified = {
                "After each hand played,",
                "{C:green}1 in #1#{} chance to create",
                "the hand's {C:planet}Planet{} card",
            },
            v_planet_tycoon_original = {
                "{C:planet}Planet{} cards appear",
                "{C:attention}#1#X{} more frequently",
                "in the shop",
            },
            v_planet_tycoon_modified = {
                "After each hand played,",
                "{C:green}1 in #1#{} chance to create",
                "the hand's {C:planet}Planet{} card",
            },
            c_wraith_original = {
                "Creates a random",
                "{C:red}Rare{C:attention} Joker{},",
                "sets money to {C:money}$0",
            },
            c_wraith_modified = {
                "Create a copy of a random",
                "{C:attention}Joker{}; all other {C:attention}Jokers{}",
                "become {C:attention}Perishable",
                "{C:inactive}(Eternal Jokers are unaffected)",
            },
            c_ankh_original = {
                "Create a copy of a",
                "random {C:attention}Joker{}, destroy",
                "all other Jokers",
            },
            c_ankh_modified = {
                "Remove all {C:attention}stickers{} from",
                "all {C:attention}Jokers{}; two random",
                "{C:attention}Jokers{} become {C:attention}Eternal",
            },
            c_hex_original = {
                "Add {C:dark_edition}Polychrome{} to a",
                "random {C:attention}Joker{}, destroy",
                "all other Jokers",
            },
            c_hex_modified = {
                "Add {C:dark_edition}Polychrome{} and a",
                "random {C:attention}sticker{} to a random",
                "{C:attention}Joker{}",
            },
            c_lovers_original = {
                "Enhances {C:attention}#1#{} selected",
                "card into a",
                "{C:attention}#2#",
            },
            c_lovers_modified = {
                "Enhances up to {C:attention}#1#{} selected",
                "cards into a",
                "{C:attention}#2#",
            },
            c_strength_original = {
                "Increases rank of",
                "up to {C:attention}#1#{} selected",
                "cards by {C:attention}1",
            },
            c_strength_modified = {
                "Select {C:attention}2{} cards",
                "The lower rank becomes",
                "the {C:attention}higher{} rank",
            },
            j_matador_original = {
                "Earn {C:money}$#1#{} if played",
                "hand triggers the",
                "{C:attention}Boss Blind{} ability",
            },
            j_matador_modified = {
                "Earn {C:money}$#1#{} for each hand",
                "played during a {C:attention}Boss Blind{}",
                "by end of the round",
            },
            j_red_card_original = {
                "This Joker gains",
                "{C:red}+#1#{} Mult when any",
                "{C:attention}Booster Pack{} is skipped",
                "{C:inactive}(Currently {C:red}+#2#{C:inactive} Mult)",
            },
            j_red_card_modified = {
                "This Joker gains {C:red}+#1#{} Mult when",
                "a {C:attention}Booster Pack{} is opened and",
                "{C:red}+#2#{} Mult when one is skipped",
                "{C:inactive}(Currently {C:red}+#3#{C:inactive} Mult)",
            },
            j_mr_bones_original = {
                "Prevents Death",
                "if chips scored",
                "are at least {C:attention}25%",
                "of required chips",
                "{S:1.1,C:red,E:2}self destructs{}",
            },
            j_mr_bones_modified = {
                "Prevents Death, then",
                "{S:1.1,C:red,E:2}self destructs{} and you",
                "go back {C:red}-1{} Ante;",
                "your run gets {C:attention}Crippled{}",
            },
            k_crippled_ex = "Crippled!",

            -- Castle joker config
            qolb_castle_checkered_label = 'Enable Castle Checkered Enhancement',
            qolb_castle_checkered_info = {
                'Castle now counts either',
                'Clubs and Spades or Hearts and Diamonds.',
                'The group follows the suits in your deck'
            },
            qolb_marble_joker_xchips_label = 'Enable Marble Joker X Chips',
            qolb_marble_joker_xchips_info = {
                'Marble Joker gains X0.1 Chips for every',
                'Stone card added to the deck,',
                'on top of its original effect'
            },
            qolb_stone_joker_mult_label = 'Enable Stone Joker Mult',
            qolb_stone_joker_mult_info = {
                'Stone Joker gives +4 Mult for each',
                'Stone Card in your full deck',
                'instead of +25 Chips'
            },
            qolb_seance_rework_label = 'Enable Seance Rework',
            qolb_seance_rework_info = {
                'Seance triggers on Straight Flush',
                'or any secret hand, and becomes Rare',
                '(cost $8 instead of $6)'
            },
            qolb_caino_rework_label = 'Enable Canio Rework',
            qolb_caino_rework_info = {
                'Canio destroys played face cards',
                'and gains X0.5 Mult per destroyed face card'
            },
            qolb_onyx_agate_label = 'Enable Onyx Agate Rework',
            qolb_onyx_agate_info = {
                'Played Club cards permanently',
                'gain +3 Mult when scored'
            },
            qolb_planet_merchant_rework_label = 'Enable Planet Merchant Rework',
            qolb_planet_merchant_rework_info = {
                'Planet Merchant and Planet Tycoon',
                'create the played hand\'s Planet card',
                '(1 in 4 / 1 in 2 chance)'
            },
            qolb_wraith_rework_label = 'Enable Wraith Rework',
            qolb_wraith_rework_info = {
                'Wraith duplicates a random Joker',
                'and makes the other Jokers Perishable'
            },
            qolb_ankh_rework_label = 'Enable Ankh Rework',
            qolb_ankh_rework_info = {
                'Ankh removes all stickers from all Jokers',
                'and makes two random Jokers Eternal'
            },
            qolb_lovers_two_cards_label = 'Enable The Lovers Two-Card Enhancement',
            qolb_lovers_two_cards_info = {
                'The Lovers can enhance up to',
                '2 selected cards at once'
            },
            qolb_strength_two_cards_label = 'Enable Strength Two-Card Rework',
            qolb_strength_two_cards_info = {
                'Strength requires selecting 2 cards:',
                'the lower rank becomes the higher rank'
            },
            qolb_hex_rework_label = 'Enable Hex Rework',
            qolb_hex_rework_info = {
                'Hex adds Polychrome and a random sticker',
                'to a random Joker without destroying the others'
            },
            qolb_matador_rework_label = 'Enable Matador Rework',
            qolb_matador_rework_info = {
                'Matador earns $5 per hand played',
                'during a Boss Blind, paid at round end'
            },
            qolb_red_card_rework_label = 'Enable Red Card Rework',
            qolb_red_card_rework_info = {
                'Red Card gains +1 Mult per Booster Pack opened',
                'and +2 Mult per Booster Pack skipped'
            },
            qolb_bull_buff_label = 'Enable Bull Buff',
            qolb_bull_buff_info = {
                'Bull gives +3 Chips for each $1'
            },
            qolb_mr_bones_rework_label = 'Enable Mr. Bones Rework',
            qolb_mr_bones_rework_info = {
                'Mr. Bones always prevents Death, self-destructs,',
                'sends you back -1 Ante and Cripples the run:',
                'money set to $0, -1 hand, -1 hand size and -1 discard; costs $10'
            },
            qolb_yorick_multiplier_label = 'Enable Yorick Multiplier Configuration',
            qolb_yorick_multiplier_info = {
                'Configure how much X Mult Yorick gains',
                'per 23 cards discarded.',
                'Default: 1.23X',
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
            beta = "Beta",
        },
    },
    descriptions = {
        Joker = {
            j_loyalty_card_scaling = {
                text = {
                    "Gains {X:red,C:white} X0.5 {} Mult after",
                    "finishing a {C:attention}blind",
                    "When {X:red,C:white}X4{} resets to {X:red,C:white}X2{}",
                    "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
                },
            },
        },
        Other = {
            crippled = {
                text = {
                    "Money set to {C:money}$0{},",
                    "{C:red}-1{} hand, {C:red}-1{} hand size,",
                    "{C:red}-1{} discard",
                },
            },
        },
    },
}
