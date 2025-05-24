return {
    descriptions = {
        Stake={
            stake_black={
                name="Mise noire",
                text={
                    "Les magasins peuvent posséder des Jokers {C:attention}Éternels{}",
                    "{C:inactive,s:0.8}(Ne peut pas être vendu ou détruit)",
                    "{s:0.8}Applique toutes les mises précédentes",
                },
            },
            stake_blue={
                name="Mise bleue",
                text={
                    "Les magasins peuvent posséder des Jokers {C:attention}périssables{}",
                    "{C:inactive,s:0.8}(Affaiblis après 5 manches)",
                    "{s:0.8}Applique toutes les mises précédentes",
                },
            },
            stake_gold={
                name="Mise d'or",
                text={
                    "Les intérêts nécessitent {C:money}6 $", -- Texte mis à jour
                    "{C:inactive,s:0.8}(au lieu de {C:money}5 ${C:inactive,s:0.8})", -- Texte mis à jour
                    "La dernière ante est {C:attention}9", -- Added text
                    "{s:0.8}S'applique à toutes les mises précédentes",
                },
            },
            stake_green={
                name="Mise verte",
                text={
                    "Le score requis augmente",
                    "plus rapidement pour chaque {C:attention}mise initiale",
                    "{s:0.8}Applique toutes les mises précédentes",
                },
            },
            stake_orange={
                name="Mise orange",
                text={
                    "Les magasins peuvent posséder des Jokers {C:attention}location{}",
                    "{C:inactive,s:0.8}(coûte {C:money,s:0.8}3 ${C:inactive,s:0.8} par manche)",
                    "{s:0.8}S'applique à toutes les mises précédentes",
                },
            },
            stake_purple={
                name="Mise violette",
                text={
                    "Le score requis augmente",
                    "plus rapidement pour chaque {C:attention}mise initiale",
                    "{s:0.8}Applique toutes les mises précédentes",
                },
            },
            stake_red={
                name="Mise rouge",
                text={
                    "Une {C:attention}Petite Blinde{} n'octroie pas",
                    "de récompense en argent",
                    "{s:0.8}Applique toutes les mises précédentes",
                },
            },
            stake_white={
                name="Mise blanche",
                text={
                    "Difficulté de base",
                },
            },
        },
    }
}
