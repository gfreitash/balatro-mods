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
            qolb_space_joker_label = 'Ativar Curinga Espacial configurável',
            qolb_space_joker_info = 'Ajustar chance do Curinga Espacial de aprimorar a mão de pôquer jogada (1=100%, 4=25%).',
            qolb_steel_joker_label = 'Ativar melhoria do Curinga de Aço',
            qolb_steel_joker_info = 'Curinga de Aço dá X0.25 de Multi por Carta de Aço (era X0.2).',
            qolb_hit_the_road_joker_label = 'Ativar reformulação do Pé na Estrada',
            qolb_hit_the_road_joker_info = { 
                'Quando ativado, Valetes descartados retornam ao baralho.',
                'O novo efeito é adicionado em conjunto com o efeito original'
            },
            qolb_square_joker_label = 'Ativar modificação do Curinga Quadrado',
            qolb_square_joker_info = {
                'Curinga Quadrado dá +2 Fichas,', 
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
            qolb_dna_uncommon_label = 'Ativar DNA Incomum',
            qolb_dna_uncommon_info = {
                'Torna o curinga DNA de raridade Incomum',
                '(custa $6 ao invés de $8)'
            },
            qolb_pareidolia_common_label = 'Ativar Pareidolia Comum',
            qolb_pareidolia_common_info = {
                'Torna o curinga Pareidolia de raridade Comum',
                '(custa $4 ao invés de $5)'
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
                'para X0.175 Multi por carta abaixo da quantidade inicial'
            },
            qolb_nerf_hanging_chad_label = 'Ativar nerf do Comprovante',
            qolb_nerf_hanging_chad_info = {
                'Torna o curinga Comprovante de raridade Incomum',
                'e mais caro (custa $8 ao invés de $6).'
            },
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
            qolb_loyalty_card_scaling_label = 'Ativar Modo Escala da Carta de Lealdade',
            qolb_loyalty_card_scaling_info = {
                'Carta de Lealdade começa em X1 de Multi, ganha',
                'X0.5 de Multi ao terminar um blind, e volta',
                'para X2 após terminar um blind em X4'
            },
            qolb_spectral_seal_clip_label = 'Cartas criadas por Espectrais podem ter Selos',
            qolb_spectral_seal_clip_info = {
                'Cartas criadas por Familiar, Sombrio e Encantamento',
                'têm chance de vir com um Selo'
            },
            qolb_spectral_seal_clip_info_paperback = {
                'Cartas criadas por Familiar, Sombrio e Encantamento',
                'têm chance de vir com um Selo',
                'ou um clipe de papel (com Paperback)'
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
                "de dar {C:chips}+#5#{} Fichas a mais.",
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
            j_splash_original = {
                "Toda {C:attention}carta jogada",
                "conta na pontuação",
            },
            j_splash_retrigger = {
                "Toda {C:attention}carta jogada",
                "conta na pontuação.",
                "{C:green}Duas cartas pontuantes aleatórias",
                "{C:green}são reativadas"
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

            -- Textos do Curinga de Mármore (do jogo base)
            j_marble_original = {
                "Adiciona uma carta de {C:attention}Pedra{}",
                "ao seu baralho quando",
                "o {C:attention}Blind{} é selecionado",
            },
            j_marble_modified = {
                "Adiciona uma carta de {C:attention}Pedra{} ao seu",
                "baralho quando o {C:attention}Blind{} é selecionado,",
                "e ganha {X:chips,C:white}X0.1{} Fichas por cada carta",
                "de {C:attention}Pedra{} adicionada ao baralho",
                "{C:inactive}(No momento {X:chips,C:white}X#1#{C:inactive} Fichas)",
            },

            -- Textos do Curinga de Pedra (do jogo base)
            j_stone_original = {
                "Dá {C:chips}+#1#{} Fichas para",
                "cada {C:attention}Carta de Pedra",
                "do seu {C:attention}baralho completo",
                "{C:inactive}(No momento, {C:chips}+#2#{C:inactive} Fichas)",
            },
            j_stone_modified = {
                "Dá {C:mult}+#1#{} Multi para",
                "cada {C:attention}Carta de Pedra",
                "do seu {C:attention}baralho completo",
                "{C:inactive}(No momento, {C:mult}+#2#{C:inactive} Multi)",
            },

            -- Textos da Sessão Mediúnica (do jogo base)
            j_seance_original = {
                "Se a {C:attention}mão de pôquer{} for",
                "{C:attention}#1#{}, cria um(a)",
                "carta {C:spectral}Espectral{} aleatória",
                "{C:inactive}(Deve ter espaço)",
            },
            j_seance_modified = {
                "Se a {C:attention}mão de pôquer{} for",
                "um {C:attention}Straight Flush{} ou uma {C:attention}mão secreta{},",
                "cria uma carta {C:spectral}Espectral{} aleatória",
                "{C:inactive}(Deve ter espaço)",
            },

            -- Textos do Caino (do jogo base)
            j_caino_original = {
                "Este Curinga ganha {X:mult,C:white} X#1# {} Multi",
                "quando uma carta de {C:attention}realeza{}",
                "é destruída",
                "{C:inactive}(No momento, {X:mult,C:white} X#2# {C:inactive} Multi)",
            },
            j_caino_modified = {
                "Destrói cartas de {C:attention}realeza{} pontuadas e",
                "ganha {X:mult,C:white} X#1# {} Multi por carta de",
                "{C:attention}realeza{} destruída",
                "{C:inactive}(No momento, {X:mult,C:white} X#2# {C:inactive} Multi)",
            },

            -- Textos da Ágata Ônix (do jogo base)
            j_onyx_agate_original = {
                "Cartas jogadas com",
                "naipe de {C:clubs}Paus{} dão",
                "{C:mult}+#1#{} Multi quando pontuadas",
            },
            j_onyx_agate_modified = {
                "Cartas jogadas de {C:clubs}Paus{} ganham",
                "permanentemente {C:mult}+#1#{} Multi",
                "quando pontuadas",
            },

            -- Textos de Familiar/Sombrio/Encantamento (do jogo base)
            c_familiar_original = {
                "Destrói {C:attention}1{} carta",
                "na sua mão, adiciona",
                "{C:attention}#1#{} {C:attention}realeza Aprimorada",
                "{C:attention}aleatórias{} na sua mão",
            },
            c_familiar_upgraded = {
                "Destrói {C:attention}1{} carta",
                "na sua mão, adiciona",
                "{C:attention}#1#{} {C:attention}realeza Aprimorada",
                "{C:attention}aleatórias{} na sua mão",
                "{C:green}Chance{} de vir com um {C:attention}Selo",
            },
            c_familiar_upgraded_paperback = {
                "Destrói {C:attention}1{} carta",
                "na sua mão, adiciona",
                "{C:attention}#1#{} {C:attention}realeza Aprimorada",
                "{C:attention}aleatórias{} na sua mão",
                "{C:green}Chance{} de vir com um {C:attention}Selo{} ou {C:attention}clipe de papel",
            },
            c_grim_original = {
                "Destrói {C:attention}1{} carta",
                "aleatória na sua mão,",
                "adiciona {C:attention}#1#{}  {C:attention}Ases",
                "{C:attention}aprimorado(s){} aleatório(s) na sua mão",
            },
            c_grim_upgraded = {
                "Destrói {C:attention}1{} carta",
                "aleatória na sua mão,",
                "adiciona {C:attention}#1#{}  {C:attention}Ases",
                "{C:attention}aprimorado(s){} aleatório(s) na sua mão",
                "{C:green}Chance{} de vir com um {C:attention}Selo",
            },
            c_grim_upgraded_paperback = {
                "Destrói {C:attention}1{} carta",
                "aleatória na sua mão,",
                "adiciona {C:attention}#1#{}  {C:attention}Ases",
                "{C:attention}aprimorado(s){} aleatório(s) na sua mão",
                "{C:green}Chance{} de vir com um {C:attention}Selo{} ou {C:attention}clipe de papel",
            },
            c_incantation_original = {
                "Destrói {C:attention}1{} carta",
                "na sua mão, adiciona {C:attention}#1#",
                "{C:attention}cartas Aprimoradas e numeradas",
                "{C:attention}aleatórias{} na sua mão",
            },
            c_incantation_upgraded = {
                "Destrói {C:attention}1{} carta",
                "na sua mão, adiciona {C:attention}#1#",
                "{C:attention}cartas Aprimoradas e numeradas",
                "{C:attention}aleatórias{} na sua mão",
                "{C:green}Chance{} de vir com um {C:attention}Selo",
            },
            c_incantation_upgraded_paperback = {
                "Destrói {C:attention}1{} carta",
                "na sua mão, adiciona {C:attention}#1#",
                "{C:attention}cartas Aprimoradas e numeradas",
                "{C:attention}aleatórias{} na sua mão",
                "{C:green}Chance{} de vir com um {C:attention}Selo{} ou {C:attention}clipe de papel",
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
                "com {C:attention}melhorias{}, {C:dark_edition}edições{},",
                "e/ou {C:attention}selos{}"
            },
            v_magic_trick_paperback = {
                "{C:attention}Cartas de jogar{} na loja podem aparecer",
                "com {C:attention}melhorias{}, {C:dark_edition}edições{},",
                "{C:attention}selos{} e {C:attention}clipes de papel{}"
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
            v_planet_merchant_original = {
                "Cartas de {C:planet}Planeta{} aparecem",
                "{C:attention}#1#X{} mais frequentemente",
                "na loja",
            },
            v_planet_merchant_modified = {
                "Após cada mão jogada,",
                "{C:green}chance de 1 em #1#{} de criar",
                "a carta de {C:planet}Planeta{} da mão",
            },
            v_planet_tycoon_original = {
                "Cartas de {C:planet}Planeta{} aparecem",
                "{C:attention}#1#X{} mais frequentemente",
                "na loja",
            },
            v_planet_tycoon_modified = {
                "Após cada mão jogada,",
                "{C:green}chance de 1 em #1#{} de criar",
                "a carta de {C:planet}Planeta{} da mão",
            },
            c_wraith_original = {
                "Cria um",
                "{C:attention}Curinga{} {C:red}Raro,",
                "define o dinheiro para {C:money}$0",
            },
            c_wraith_modified = {
                "Cria uma cópia de um {C:attention}Curinga",
                "aleatório{}; todos os outros {C:attention}Curingas",
                "ficam {C:attention}Perecíveis",
                "{C:inactive}(Curingas Eternos não são afetados)",
            },
            c_ankh_original = {
                "Cria uma cópia de um",
                "{C:attention}Curinga{} aleatório, destrói",
                "todos os outros Curingas",
            },
            c_ankh_modified = {
                "Remove todos os {C:attention}adesivos{} de",
                "todos os {C:attention}Curingas{}; dois {C:attention}Curingas",
                "aleatórios ficam {C:attention}Eternos",
            },
            c_hex_original = {
                "Adiciona {C:dark_edition}Policromático{} a um",
                "{C:attention}Curinga{} aleatório, destrói",
                "todos os outros Curingas",
            },
            c_hex_modified = {
                "Adiciona {C:dark_edition}Policromático{} e um",
                "{C:attention}adesivo{} aleatório a um",
                "{C:attention}Curinga{} aleatório",
            },
            c_lovers_original = {
                "Aprimora {C:attention}#1#{} carta",
                "selecionada para",
                "{C:attention}#2#",
            },
            c_lovers_modified = {
                "Aprimora até {C:attention}#1#{} cartas",
                "selecionadas para",
                "{C:attention}#2#",
            },
            j_matador_original = {
                "Ganhe {C:money}$#1#{} se a",
                "mão jogada ativa a",
                "habilidade {C:attention}Blind de Chefe{}",
            },
            j_matador_modified = {
                "Ganhe {C:money}$#1#{} por mão",
                "jogada durante um {C:attention}Blind de Chefe{}",
                "{C:inactive}(pago no fim da rodada)",
            },
            j_red_card_original = {
                "Este Curinga ganha",
                "{C:red}+#1#{} Multi quando qualquer",
                "{C:attention}Pacote de Reforço{} é ignorado",
                "{C:inactive}(No momento, {C:red}+#2#{C:inactive} Multi)",
            },
            j_red_card_modified = {
                "Este Curinga ganha {C:red}+#1#{} Multi quando",
                "um {C:attention}Pacote de Reforço{} é aberto e",
                "{C:red}+#2#{} Multi quando um é ignorado",
                "{C:inactive}(No momento, {C:red}+#3#{C:inactive} Multi)",
            },
            j_mr_bones_original = {
                "Evita a Morte",
                "se as fichas pontuadas",
                "forem, pelo menos, {C:attention}25%",
                "das fichas necessárias",
                "{S:1.1,C:red,E:2}se autodestrói{}",
            },
            j_mr_bones_modified = {
                "Evita a Morte, depois",
                "{S:1.1,C:red,E:2}se autodestrói{} e sua",
                "run fica {C:attention}Aleijada{}",
                "{C:inactive}(veja o tooltip Aleijada)",
            },
            k_crippled_ex = "Aleijado!",

            -- Castle joker config
            qolb_castle_checkered_label = 'Ativar Castelo com melhoria Xadrez',
            qolb_castle_checkered_info = {
                'Castelo agora conta ou',
                'Paus e Espadas ou Copas e Ouros.',
                'O grupo acompanha os naipes do seu baralho'
            },
            qolb_marble_joker_xchips_label = 'Ativar X Fichas do Curinga de Mármore',
            qolb_marble_joker_xchips_info = {
                'Curinga de Mármore ganha X0.1 Fichas por cada',
                'carta de Pedra adicionada ao baralho,',
                'além do seu efeito original'
            },
            qolb_stone_joker_mult_label = 'Ativar Multi do Curinga de Pedra',
            qolb_stone_joker_mult_info = {
                'Curinga de Pedra dá +4 de Multi por cada',
                'Carta de Pedra no baralho completo',
                'ao invés de +25 Fichas'
            },
            qolb_seance_rework_label = 'Ativar reformulação da Sessão Mediúnica',
            qolb_seance_rework_info = {
                'Sessão Mediúnica ativa em Straight Flush',
                'ou qualquer mão secreta, e vira Rara',
                '(custa $8 ao invés de $6)'
            },
            qolb_caino_rework_label = 'Ativar reformulação do Caino',
            qolb_caino_rework_info = {
                'Caino destrói cartas de realeza pontuadas',
                'e ganha X0.25 de Multi por carta destruída'
            },
            qolb_onyx_agate_label = 'Ativar reformulação da Ágata Ônix',
            qolb_onyx_agate_info = {
                'Cartas de Paus jogadas ganham',
                'permanentemente +3 de Multi ao pontuar'
            },
            qolb_planet_merchant_rework_label = 'Ativar reformulação do Comerciante de Planetas',
            qolb_planet_merchant_rework_info = {
                'Comerciante e Magnata dos Planetas',
                'criam a carta de Planeta da mão jogada',
                '(chance de 1 em 4 / 1 em 2)'
            },
            qolb_wraith_rework_label = 'Ativar reformulação do Espectro',
            qolb_wraith_rework_info = {
                'O Espectro duplica um Curinga aleatório',
                'e torna os outros Curingas Perecíveis'
            },
            qolb_ankh_rework_label = 'Ativar reformulação do Ankh',
            qolb_ankh_rework_info = {
                'O Ankh remove todos os adesivos de todos os Curingas',
                'e torna dois Curingas aleatórios Eternos'
            },
            qolb_lovers_two_cards_label = 'Ativar melhoria de 2 cartas dos Amantes',
            qolb_lovers_two_cards_info = {
                'Os Amantes podem aprimorar até',
                '2 cartas selecionadas'
            },
            qolb_hex_rework_label = 'Ativar reformulação do Feitiço',
            qolb_hex_rework_info = {
                'O Feitiço adiciona Poli e um adesivo aleatório',
                'a um Curinga sem destruir os outros'
            },
            qolb_matador_rework_label = 'Ativar reformulação do Matador',
            qolb_matador_rework_info = {
                'O Matador ganha $5 por mão jogada',
                'durante um Blind de Chefe, pago no fim da rodada'
            },
            qolb_red_card_rework_label = 'Ativar reformulação da Carta Vermelha',
            qolb_red_card_rework_info = {
                'A Carta Vermelha ganha +1 Multi por pacote aberto',
                'e +2 Multi por pacote ignorado'
            },
            qolb_bull_buff_label = 'Ativar melhoria do Touro',
            qolb_bull_buff_info = {
                'O Touro dá +3 Fichas por $1'
            },
            qolb_mr_bones_rework_label = 'Ativar reformulação do Sr. Osso',
            qolb_mr_bones_rework_info = {
                'O Sr. Osso sempre evita a Morte, mas se autodestrói',
                'e Aleija a run: dinheiro $0, -1 Ante,',
                '-1 mão, -1 tamanho da mão e -1 descarte; custa $10'
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
            beta = "Beta",
        },
        v_dictionary = {
            -- Fallback for keys Steamodded does not ship in pt_BR (used by the Marble Joker float)
            a_xchips = "X#1# Fichas",
            a_xchips_minus = "-X#1# Fichas",
        },
    },
    descriptions = {
        Joker = {
            j_loyalty_card_scaling = {
                text = {
                    "{X:red,C:white} X#1# {} de Multi",
                    "Ganha {X:red,C:white} X0.5 {} de Multi ao terminar",
                    "um {C:attention}blind",
                    "Volta para {X:red,C:white}X2{} após terminar",
                    "um blind em {X:red,C:white}X4{}",
                },
            },
        },
        Other = {
            crippled = {
                text = {
                    "Sua run está {C:attention}Aleijada{}:",
                    "dinheiro definido para {C:money}$0{},",
                    "{C:attention}-1{} Ante, {C:attention}-1{} mão,",
                    "{C:attention}-1{} tamanho da mão, {C:attention}-1{} descarte",
                },
            },
        },
    },
}
