return {
    descriptions = {
        Stake={
            stake_black={
                name="黑色賭注",
                text={
                    "商店有{C:attention}永存{}小丑牌",
                    "{C:inactive,s:0.8}(無法賣出或摧毀)",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_blue={
                name="藍色賭注",
                text={
                    "商店可出現{C:attention}非保久{}小丑", -- Consistent with English and patch
                    "{C:inactive,s:0.8}(5回合後遭減益)", -- Consistent with English and patch
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_gold={
                name="金色賭注",
                text={
                    "利息需要{C:money}$6", -- Consistent with English and patch
                    "{C:inactive,s:0.8}(取代{C:money}$5{C:inactive,s:0.8})", -- Consistent with English and patch
                    "最終底注為 {C:attention}9", -- Added text
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_green={
                name="綠色賭注",
                text={
                    "每個{C:attention}底注所需分數",
                    "以更快的尺度提高",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_orange={
                name="橘色賭注",
                text={
                    "商店可出現{C:attention}租賃{}小丑", -- Consistent with English and patch
                    "{C:inactive,s:0.8}(每回合花費{C:money,s:0.8}$3{C:inactive,s:0.8})", -- Consistent with English and patch (removed the $1 purchase text as it's not in the patch logic)
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_purple={
                name="紫色賭注",
                text={
                    "每個{C:attention}底注所需分數",
                    "以更快的尺度提高",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_red={
                name="紅色賭注",
                text={
                    "{C:attention}小盲注{}",
                    "無獎勵金",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_white={
                name="白色賭注",
                text={
                    "基本難度",
                },
            },
        },
    }
}
