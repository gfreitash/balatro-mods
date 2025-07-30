return {
    descriptions = {
        Joker = {
            j_hit_the_road = {
                name = "Hit the Road",
                text = {
                    "This Joker gains {X:mult,C:white} X#1# {} Mult",
                    "for every {C:attention}Jack{} discarded this round,",
                    "and discarded {C:attention}Jacks{} are returned to deck.",
                    "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)"
                },
                unlock = {
                    "Discard {E:1,C:attention}5",
                    "{E:1,C:attention}Jacks{} at the",
                    "same time",
                },
            },
            j_square = {
                name = "Square Joker",
                text = {
                    "This Joker gains {C:chips}+#2#{} Chips",
                    "if played hand has exactly {C:attention}4{} cards.",
                    "Each scoring card has {C:green}#3# in #4#{} chance",
                    "to give {C:chips}+#2#{} more Chips.",
                    "{C:inactive}(Currently {C:chips}#1#{C:inactive} Chips)",
                },
            },
        },
    },
    misc = {
        dictionary={
            qolb_mod_name = 'QoL Bundle',
            qolb_mod_description = 'A collection of quality-of-life improvements for Balatro.',
            qolb_shop_size_label = 'Enable Increased Shop Size',
            qolb_shop_size_info = 'Increases shop size by 1',
            qolb_wildcard_fix_label = 'Enable Wildcard/Smeared Joker Fix',
            qolb_wildcard_fix_info = { 
                'Prevents Wildcard/Smeared Joker from being debuffed',
                'by suit debuffs'
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
            qolb_nerf_photochad_label = 'Enable Nerf Photochad',
            qolb_nerf_photochad_info = 'Makes Photograph and Hanging Chad jokers Uncommon rarity.',
        },
    },
}
