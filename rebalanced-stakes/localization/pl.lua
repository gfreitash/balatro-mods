return {
    descriptions = {
        Stake={
            stake_black={
                name="Czarna stawka",
                text={
                    "W sklepie mogą pojawić się {C:attention}Wieczne{} Jokery",
                    "{C:inactive,s:0.8}(Nie można ich sprzedać lub zniszczyć)",
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_blue={
                name="Niebieska stawka",
                text={
                    "W sklepie mogą pojawić się {C:attention}nietrwałe{} jokery",
                    "{C:inactive,s:0.8}(osłabiane po 5 rundach)",
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_gold={
                name="Złota stawka",
                text={
                    "Odsetki wymagają {C:money}6 $", -- Zaktualizowany tekst
                    "{C:inactive,s:0.8}(zamiast {C:money}5 ${C:inactive,s:0.8})", -- Zaktualizowany tekst
                    "Ostatnia ante to {C:attention}9", -- Added text
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_green={
                name="Zielona stawka",
                text={
                    "Wymagany wynik skaluje się",
                    "szybciej dla każdego {C:attention}wejścia",
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_orange={
                name="Pomarańczowa stawka",
                text={
                    "Sklepy mogą mieć {C:attention}wypożyczane{} jokery",
                    "{C:inactive,s:0.8}(kosztują {C:money,s:0.8}$3{C:inactive,s:0.8} na rundę).",
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_purple={
                name="Fioletowa stawka",
                text={
                    "Wymagany wynik skaluje się",
                    "szybciej dla każdego {C:attention}wejścia",
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_red={
                name="Czerwona stawka",
                text={
                    "{C:attention}Mała w ciemno{} nie daje",
                    "nagrody pieniężnej",
                    "{s:0.8}Działa na wszystkie poprzednie stawki",
                },
            },
            stake_white={
                name="Biała stawka",
                text={
                    "Trudność podstawowa",
                },
            },
        },
    }
}
