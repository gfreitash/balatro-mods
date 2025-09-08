return {
    misc = {
        dictionary={
            qolb_mod_name = 'Pacote QoL',
            qolb_mod_description = 'Uma coleção de melhorias de qualidade de vida para Balatro.',
            qolb_shop_size_label = 'Ativar tamanho aumentado da loja',
            qolb_shop_size_info = 'Aumenta o tamanho da loja em 1',
            qolb_wildcard_fix_label = 'Ativar correção do Curinga/Curinga Borrado',
            qolb_wildcard_fix_info = {
                'Impede que o Naipe Curinga/Curinga Borrado',
                'seja colocado em desvantagem por desvantagem de naipes',
                'Se Paperback estiver presente,',
                'Curinga Borrado considerará Coroas/Estrelas',

            },
            qolb_wheel_fortune_label = 'Ativar Roda da Fortuna mais fácil',
            qolb_wheel_fortune_info = 'Ajustar facilidade da Roda da Fortuna (1=100%, 4=25%).',
            qolb_unweighted_editions_label = 'Ativar edições base sem peso',
            qolb_unweighted_editions_info = 'Torna edições Laminado, Holográfico e Policromático igualmente prováveis.',
            qolb_eight_ball_joker_label = 'Ativar Bola 8 configurável',
            qolb_eight_ball_joker_info = 'Ajustar chance da Bola 8 gerar cartas Tarô (1=100%, 4=25%).',
            qolb_hit_the_road_joker_label = 'Ativar reformulação do Pé na Estrada',
            qolb_hit_the_road_joker_info = { 
                'Quando ativado, Valetes descartados retornam ao baralho.',
                'O novo efeito é adicionado em conjunto com o efeito original'
            },
            qolb_square_joker_label = 'Ativar modificação do Curinga Quadrado',
            qolb_square_joker_info = {
                'Curinga Quadrado dá +4 Fichas,', 
                'cada carta pontuando tem 1 em 2 chance de dar +4 mais.',
                'Raridade Incomum.',
            },
            qolb_flower_pot_wildcard_label = 'Ativar ajuste do Vaso de Flores',
            qolb_flower_pot_wildcard_info = {
                'Vaso de Flores só aparece na loja',
                'quando cartas com melhoria Naipe Curinga existem no baralho.',
                'Ativa se a mão tem Naipe Curinga.'
            },
            qolb_baron_uncommon_label = 'Ativar Barão Incomum',
            qolb_baron_uncommon_info = {
                'Torna o curinga Barão de raridade Incomum',
                '(custa $5 ao invés de $8)'
            },
            qolb_mime_rare_label = 'Ativar Mímico Raro',
            qolb_mime_rare_info = {
                'Torna o curinga Mímico de raridade Rara.',
                '(custa $6 ao invés de $5)'
            },
            qolb_ceremonial_dagger_common_label = 'Ativar Adaga Cerimonial Comum',
            qolb_ceremonial_dagger_common_info = {
                'Torna a Adaga Cerimonial de raridade Comum',
                '(custa $3 ao invés de $6)'
            },
            qolb_mail_in_rebate_uncommon_label = 'Nerfar Desconto de Correio para Incomum',
            qolb_mail_in_rebate_uncommon_info = {
                'Nerfa o curinga Desconto de Correio para raridade Incomum',
                '(era raridade Comum - torna mais raro)'
            },
            qolb_fortune_teller_cheaper_label = 'Bufar custo do Vidente',
            qolb_fortune_teller_cheaper_info = {
                'Torna o curinga Vidente mais barato',
                '(custa $4 ao invés de $6)'
            },
            qolb_erosion_xmult_label = 'Reformular Erosão para X Multi',
            qolb_erosion_xmult_info = {
                'Muda Erosão de +4 Multi por carta',
                'para X0.2 Multi por carta abaixo da quantidade inicial'
            },
            qolb_nerf_hanging_chad_label = 'Ativar nerf do Comprovante',
            qolb_nerf_hanging_chad_info = 'Torna o curinga Comprovante de raridade Incomum e mais caro (custa $8 ao invés de $6).',
            qolb_satellite_joker_label = 'Ativar reformulação do Satélite',
            qolb_satellite_joker_info = {
                'Satélite agora dá dinheiro igual à metade',
                'do nível mais alto de mão de pôquer (arredondado para baixo)'
            },
            qolb_sigil_control_label = 'Ativar Símbolo controlado',
            qolb_sigil_control_info = {
                'Símbolo agora requer selecionar uma carta primeiro.',
                'Todas as cartas na mão são convertidas para o',
                'naipe da carta selecionada ao invés de naipe aleatório.'
            },
            qolb_ouija_control_label = 'Ativar Ouija controlado',
            qolb_ouija_control_info = {
                'Ouija agora requer selecionar uma carta primeiro.',
                'Todas as cartas na mão são convertidas para a',
                'classe da carta selecionada ao invés de classe aleatória.'
            },
            qolb_loyalty_card_rounds_label = 'Habilitar Modo Rodadas do Carta de Lealdade',
            qolb_loyalty_card_rounds_info = {
                'Carta de Lealdade é ativada com base em rodadas (apostas)',
                'ao invés de mãos jogadas para timing mais previsível.'
            },
            qolb_splash_joker_retrigger_label = 'Habilitar Reativação do Splash',
            qolb_splash_joker_retrigger_info = {
                'O Splash Joker adicionalmente reativa',
                'uma carta pontuante aleatória'
            },
            qolb_interest_on_skip_label = 'Ativar Juros ao Pular',
            qolb_interest_on_skip_info = {
                'Ganhe juros quando pular blinds.',
                'Juros são calculados e concedidos',
                'antes de obter a marca'
            },

            -- Textos espectrais originais (do jogo base)
            sigil_loc_text_original = {
                "Converte todas as cartas",
                "da mão em um único",
                "{C:attention}naipe aleatório",
            },
            sigil_loc_text_controlled = {
                "Converte todas as cartas da mão",
                "para o mesmo {C:attention}naipe{} da",
                "{C:attention}1{} carta selecionada"
            },
            ouija_loc_text_original = {
                "Converte todas as cartas",
                "da mão em uma única",
                "{C:attention}classe aleatória",
                "{C:red}-1{} de tamanho de mão",
            },
            ouija_loc_text_controlled = {
                "Converte todas as cartas da mão",
                "para a mesma {C:attention}classe{} da",
                "{C:attention}1{} carta selecionada",
                "{C:red}-1{} de tamanho de mão",
            },

            -- Textos originais dos curingas (do jogo base)
            j_hit_the_road_original = {
                "Este Curinga ganha {X:mult,C:white} X#1# {} Multi",
                "para cada {C:attention}Valete{}",
                "descartado nesta rodada",
                "{C:inactive}(No momento, {X:mult,C:white} X#2# {C:inactive} Multi)"
            },
            j_hit_the_road_modified = {
                "Este Curinga ganha {X:mult,C:white} X#1# {} Multi",
                "para cada {C:attention}Valete{} descartado nesta rodada,",
                "e {C:attention}Valetes{} descartados retornam ao baralho.",
                "{C:inactive}(No momento, {X:mult,C:white} X#2# {C:inactive} Multi)"
            },
            j_square_original = {
                "Este Curinga ganha {C:chips}+#2#{} Fichas",
                "se a mão jogada tem",
                "exatamente {C:attention}4{} cartas",
                "{C:inactive}(No momento, {C:chips}+#1#{C:inactive} Fichas)"
            },
            j_square_modified = {
                "Este Curinga ganha {C:chips}+#2#{} Fichas",
                "se a mão jogada tem exatamente {C:attention}4{} cartas.",
                "Cada carta pontuando tem {C:green}#3# em #4#{} chance",
                "de dar {C:chips}+#2#{} Fichas a mais.",
                "{C:inactive}(No momento, {C:chips}+#1#{C:inactive} Fichas)"
            },
            j_flower_pot_original = {
                "{X:mult,C:white} X#1# {} Multi se a mão",
                "de pôquer contém",
                "uma carta de {C:diamonds}Ouros{}, uma carta de {C:clubs}Paus{},",
                "uma carta de {C:hearts}Copas{} e uma carta de {C:spades}Espadas{}"
            },
            j_flower_pot_modified = {
                "{X:mult,C:white} X#1# {} Multi se a mão de pôquer",
                "contém uma {C:attention}Carta Selvagem"
            },
            j_satellite_original = {
                "Ganhe {C:money}$#1#{} no fim da",
                "rodada por {C:planet}Planeta{} único",
                "usada nesta tentativa",
                "{C:inactive}(No momento {C:money}$#2#{C:inactive})",
            },
            j_satellite_modified = {
                "Ganhe {C:money}$#1#{} no fim da rodada para cada",
                "{C:attention}2{} níveis da sua mão de pôquer mais alta",
                "{C:inactive}(No momento {C:money}$#2#{C:inactive})"
            },
            j_loyalty_card_original = {
                "{X:red,C:white} X#1# {} Multi a cada",
                "{C:attention}#2#{} mãos jogadas",
                "{C:inactive}#3#",
            },
            j_loyalty_card_rounds = {
                "{X:red,C:white} X#1# {} Multi a cada",
                "{C:attention}#2#{} rodadas",
                "{C:inactive}#3#",
            },
            j_splash_original = {
                "Toda {C:attention}carta jogada",
                "conta na pontuação",
            },
            j_splash_retrigger = {
                "Toda {C:attention}carta jogada",
                "conta na pontuação.",
                "{C:green}Carta pontuante aleatória",
                "{C:green}é reativada"
            },

            j_erosion_original = {
                "{C:red}+#1#{} Multi por cada",
                "carta abaixo de {C:attention}#2#{}",
                "no seu baralho completo",
                "{C:inactive}(No momento {C:red}+#3#{C:inactive} Multi)",
            },
            j_erosion_xmult = {
                "{X:mult,C:white}X#1#{} Multi por cada",
                "carta abaixo de {C:attention}#2#{}",
                "no seu baralho completo",
                "{C:inactive}(No momento {X:mult,C:white}X#3#{C:inactive} Multi)",
            },

            -- Enhanced voucher config labels
            qolb_enhanced_magic_trick_label = 'Ativar Truque de Mágica Melhorado',
            qolb_enhanced_magic_trick_info = {
                'Truque de Mágica gera cartas de jogar com',
                'melhorias, edições, selos',
                'e clipes (se Paperback estiver presente)'
            },
            qolb_new_illusion_label = 'Ativar Nova Ilusão',
            qolb_new_illusion_info = {
                'Ilusão gera cartas do seu baralho',
                'e rerrola suas melhorias enquanto',
                'preserva as existentes se a rerrolagem falhar'
            },

            -- Original voucher texts (from base game)
            v_magic_trick_original = {
                "{C:attention}Cartas de jogar{} podem",
                "ser compradas",
                "na {C:attention}loja",
            },
            v_magic_trick_enhanced = {
                "{C:attention}Cartas de jogar{} na loja podem aparecer",
                "com {C:attention}melhorias{}, {C:dark_edition}edições{}, {C:attention}selos{},",
                "ou {C:attention}clipes de papel{} (se Paperback estiver presente)."
            },
            v_illusion_original = {
                "{C:attention}Cartas de jogar{} podem",
                "ter uma {C:enhanced}Melhoria",
                "quando aparecem",
                "na {C:attention}loja"
            },
            v_illusion_deck_based = {
                "{C:attention}Cartas de jogar{} na loja são",
                "{C:attention}clones{} de cartas no seu {C:attention}baralho,",
                "e seus aprimoramentos podem ser {C:attention}rerrolados{}."
            },

            -- Castle joker config
            qolb_castle_checkered_label = 'Ativar Castelo com melhoria Xadrez',
            qolb_castle_checkered_info = {
                'Castelo agora conta ou',
                'Paus e Espadas ou Copas e Ouros.',
                'Consistente como no baralho xadrez.'
            },
            qolb_yorick_multiplier_label = 'Ativar Configuração do Multiplicador do Yorick',
            qolb_yorick_multiplier_info = {
                'Configure quanto XMulti Yorick ganha',
                'por 23 cartas descartadas.',
                'Padrão: 1.5X',
            },

            -- Smeared joker texts (from base game)
            j_smeared_original = {
                "{C:hearts}Copas{} e {C:diamonds}Ouros",
                "contam como o mesmo naipe,",
                "{C:spades}Espadas{} e {C:clubs}Paus",
                "contam como o mesmo naipe",
            },
            j_smeared_paperback = {
                "{C:paperback_light_suit}Naipes claros{} contam",
                "como o mesmo naipe,",
                "{C:paperback_dark_suit}Naipes escuros{} contam",
                "como o mesmo naipe",
            },

            -- Castle joker texts (from base game)
            j_castle_original = {
                "Este Curinga ganha {C:chips}+#1#{} Fichas",
                "por cada carta {V:1}#2#{} descartada,",
                "naipe muda em cada rodada",
                "{C:inactive}(No momento {C:chips}+#3#{C:inactive} Fichas)",
            },
            j_castle_checkered = {
                "Este Curinga ganha {C:chips}+#1#{} Fichas por carta",
                "{V:1}#2#{} ou {V:2}#3#{} descartada, grupo de naipes muda em cada rodada",
                "{C:inactive}(No momento {C:chips}+#4#{C:inactive} Fichas)",
            },
            j_castle_checkered_paperback = {
                "Este Curinga ganha {C:chips}+#1#{} Fichas",
                "por cada carta de {C:attention}#2#{} descartada,",
                "grupo de naipes muda em cada rodada",
                "{C:inactive}(No momento {C:chips}+#3#{C:inactive} Fichas)",
            },

            requires_restart = "Requer reinicialização",
        },
    },
}
