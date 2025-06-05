-- QoL Bundle/src/wheel_of_fortune.lua

-- Override the Wheel of Fortune consumable
-- Needs restart
SMODS.Consumable:take_ownership('wheel_of_fortune', {
    config = {
        extra = QOL_BUNDLE.config.wheel_of_fortune_enabled and QOL_BUNDLE.config.wheel_of_fortune_value or 4
    }
})
