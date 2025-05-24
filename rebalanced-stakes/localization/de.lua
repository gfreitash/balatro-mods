return {
    descriptions = {
        Stake={
            stake_black={
                name="Schwarzer Einsatz",
                text={
                    "Shop kann {C:attention}ewige{} Joker haben",
                    "{C:inactive,s:0.8}(Kann nicht verkauft oder zerstört werden)",
                    "{s:0.8}Gilt für alle vorherigen Einsätze",
                },
            },
            stake_blue={
                name="Blauer Einsatz",
                text={
                    "Shop kann {C:attention}verderbliche{} Joker haben.",
                    "{C:inactive,s:0.8}(Werden nach 5 Runden geschwächt)",
                    "{s:0.8}Gilt für alle vorherigen Einsätze.",
                },
            },
            stake_gold={
                name="Goldener Einsatz",
                text={
                    "Zinsen ab {C:money}$6", -- Updated text: Interest from $6
                    "{C:inactive,s:0.8}(statt {C:money}$5{C:inactive,s:0.8})", -- Updated text: (instead of $5)
                    "Der letzte Ante ist {C:attention}9", -- Added text: Final ante is 9
                    "{s:0.8}Gilt für alle vorherigen Einsätze.",
                },
            },
            stake_green={
                name="Grüner Einsatz",
                text={
                    "Benötigte Punktzahl skaliert",
                    "schneller für jede {C:attention}Ante",
                    "{s:0.8}Gilt für alle vorherigen Einsätze",
                },
            },
            stake_orange={
                name="Orangener Einsatz",
                text={
                    "Shop kann {C:attention}gemietete{} Joker haben.",
                    "{C:inactive,s:0.8}(Kosten {C:money,s:0.8}3 ${C:inactive,s:0.8} pro Runde)",
                    "{s:0.8}Gilt für alle vorherigen Einsätze.",
                },
            },
            stake_purple={
                name="Lila Einsatz",
                text={
                    "Benötigte Punktzahl skaliert",
                    "schneller für jede {C:attention}Ante",
                    "{s:0.8}Gilt für alle vorherigen Einsätze",
                },
            },
            stake_red={
                name="Roter Einsatz",
                text={
                    "{C:attention}Small Blind{} gibt",
                    "kein Belohnungsgeld",
                    "{s:0.8}Gilt für alle vorherigen Einsätze",
                },
            },
            stake_white={
                name="Weißer Einsatz",
                text={
                    "Basis-Schwierigkeit",
                },
            },
        },
    }
}
