return {
    descriptions = {
        Other = {
            blac_black_seal = {
                name = 'Selo Preto',
                text = {
                    'Se você jogar apenas esta carta:',
                    'adicione {C:dark_edition}negativo{} a um {C:attention}Curinga{} aleatório',
                    'remova todos os {C:dark_edition}selos pretos{} do seu baralho',
                    '{C:inactive}(Efeito não é ativado se a carta estiver com desvantagem){}',
                },
            },
        },
    },
    misc = {
        labels = {
            blac_black_seal = 'Selo Preto',
        },
        dictionary = {
            black_seal = 'Selo Preto',
            black_seal_spawn_percentage = 'Porcentagem de geração do selo preto',
            override_ectoplasm_effect = 'Sobrescrever efeito do ectoplasma',
            ectoplasm_override_reduces_hand = 'Ectoplasma reduz tamanho da mão',
            debug_logging_enabled = 'Ativar registro de debug',
            debug_keybinds_enabled = 'Ativar teclas de debug',
            black_seal_spawn_percentage_info1 = 'Chance percentual (%) de um selo preto ser escolhido aleatoriamente.',
            black_seal_spawn_percentage_info2 = '0% = Nunca gerar; 100% = Apenas selos pretos são gerados.',
            black_seal_spawn_percentage_info3 = 'Chance igual com outros selos: %s%%.',
            override_ectoplasm_effect_info = 'Ectoplasma adiciona um selo preto a uma carta.',
            ectoplasm_override_reduces_hand_info = 'Se o ectoplasma deve reduzir o tamanho da mão',
            debug_logging_enabled_info = 'Registra ações detalhadas do mod no console.',
            debug_keybinds_enabled_info = 'Ativa teclas de teste. Requer reinicialização.',

            ectoplasm_loc_text_original = {
                "Adiciona {C:dark_edition}Negativo{} a",
                "um {C:attention}Curinga aleatório,",
                "{C:red}-#1#{} tamanho da mão",
            },
            ectoplasm_loc_text_override = {
                "Adiciona um {C:dark_edition}Selo Preto{}",
                "a {C:attention}1{} carta ",
                "selecionada na sua mão"
            },
            ectoplasm_hand_size_line = "{C:red}-#1#{} tamanho da mão",

        },
    },
}