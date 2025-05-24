return {
    descriptions = {
        Stake={
            stake_black={
                name="黑注",
                text={
                    "商店可能会出现{C:attention}永恒{}小丑牌",
                    "{C:inactive,s:0.8}(无法卖出或摧毁)",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_blue={
                name="蓝注",
                text={
                    "商店可能会出现{C:attention}易腐{}小丑牌", -- Consistent with English and patch
                    "{C:inactive,s:0.8}(经过5回合后被削弱)", -- Consistent with English and patch
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_gold={
                name="金注",
                text={
                    "利息需要{C:money}$6", -- Consistent with English and patch
                    "{C:inactive,s:0.8}(取代{C:money}$5{C:inactive,s:0.8})", -- Consistent with English and patch
                    "最终底注为 {C:attention}9", -- Added text
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_green={
                name="绿注",
                text={
                    "{C:attention}底注{}提升时",
                    "过关需求分数的增速更快",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_orange={
                name="橙注",
                text={
                    "商店可能会出现{C:attention}租用{}小丑牌", -- Consistent with English and patch
                    "{C:inactive,s:0.8}(每回合花费{C:money,s:0.8}$3{C:inactive,s:0.8})", -- Consistent with English and patch (removed the $1 purchase text as it's not in the patch logic)
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_purple={
                name="紫注",
                text={
                    "{C:attention}底注{}提升时",
                    "过关需求分数的增速更快",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_red={
                name="红注",
                text={
                    "{C:attention}小盲注{}",
                    "没有奖励金",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_white={
                name="白注",
                text={
                    "基础难度",
                },
            },
        },
    }
}
