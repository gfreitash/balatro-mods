return {
    descriptions = {
        Stake={
            stake_black={
                name="Aposta Preta",
                text={
                    "A loja pode ter Curingas {C:attention}Eternos{}",
                    "{C:inactive,s:0.8}(Não é possível vender ou destruir)",
                    "{s:0.8}Aplica todas as Apostas anteriores",
                },
            },
            stake_blue={
                name="Aposta Azul",
                text={
                    "A loja pode ter Curingas {C:attention}Perecíveis{}",
                    "{C:inactive,s:0.8}(Com desvantagem após 5 Rodadas)",
                    "{s:0.8}Aplica todas as Apostas anteriores",
                },
            },
            stake_gold={
                name="Aposta Dourada",
                text={
                    "Juros requerem {C:money}$6", -- Texto atualizado
                    "{C:inactive,s:0.8}(em vez de {C:money}$5{C:inactive,s:0.8})", -- Texto atualizado
                    "Ante Final é {C:attention}9", -- Added text
                    "{s:0.8}Aplica-se a todas as Apostas anteriores",
                },
            },
            stake_green={
                name="Aposta Verde",
                text={
                    "A pontuação necessária escala",
                    "cada vez mais rapidamente com cada {C:attention}Aposta",
                    "{s:0.8}Aplica todas as Apostas anteriores",
                },
            },
            stake_orange={
                name="Aposta Laranja",
                text={
                    "A loja pode ter Curingas de {C:attention}Aluguel{}",
                    "{C:inactive,s:0.8}(Custa {C:money,s:0.8}$3{C:inactive,s:0.8} por rodada)",
                    "{s:0.8}Aplica-se a todas as Apostas anteriores",
                },
            },
            stake_purple={
                name="Aposta Roxa",
                text={
                    "A pontuação necessária escala",
                    "cada vez mais rapidamente com cada {C:attention}Aposta",
                    "{s:0.8}Aplica todas as Apostas anteriores",
                },
            },
            stake_red={
                name="Aposta Vermelha",
                text={
                    "{C:attention}Small Blind{} não dá",
                    "recompensas em dinheiro",
                    "{s:0.8}Aplica todas as Apostas anteriores",
                },
            },
            stake_white={
                name="Aposta Branca",
                text={
                    "Dificuldade Base",
                },
            },
        },
    }
}
