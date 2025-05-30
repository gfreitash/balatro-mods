return {
    descriptions = {
        Stake={
            stake_black={
                name="Черная ставка",
                text={
                    "В лавке могут быть {C:attention}вечные{} джокеры",
                    "{C:inactive,s:0.8}(нельзя продать или уничтожить)",
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_blue={
                name="Синяя ставка",
                text={
                    "В лавке могут появиться {C:attention}портящиеся{} джокеры",
                    "{C:inactive,s:0.8}(Ослабляется после 5 раундов)",
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_gold={
                name="Золотая ставка",
                text={
                    "Проценты требуют {C:money}6 $", -- Обновленный текст
                    "{C:inactive,s:0.8}(вместо {C:money}5 ${C:inactive,s:0.8})", -- Обновленный текст
                    "Последнее анте — {C:attention}9", -- Added text
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_green={
                name="Зеленая ставка",
                text={
                    "Требуемые очки масштабируются",
                    "быстрее для каждого {C:attention}анте",
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_orange={
                name="Оранжевая ставка",
                text={
                    "В лавке могут появиться {C:attention}прокатные{} джокеры",
                    "{C:inactive,s:0.8}(Стоимость: {C:money,s:0.8}3 ${C:inactive,s:0.8} за раунд)",
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_purple={
                name="Фиолетовая ставка",
                text={
                    "Требуемые очки масштабируются",
                    "быстрее для каждого {C:attention}анте",
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_red={
                name="Красная ставка",
                text={
                    "{C:attention}Малый блайнд{} не дает",
                    "денег в награду",
                    "{s:0.8}Применяет все предыдущие ставки",
                },
            },
            stake_white={
                name="Белая ставка",
                text={
                    "Базовая сложность",
                },
            },
        },
    }
}
