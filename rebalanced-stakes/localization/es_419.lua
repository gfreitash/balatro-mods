return {
    descriptions = {
        Stake={
            stake_black={
                name="Pozo negro",
                text={
                    "La tienda puede tener comodines {C:attention}eternos{}",
                    "{C:inactive,s:0.8}(No se pueden vender ni destruir)",
                    "{s:0.8}Se aplica a todos los pozos anteriores",
                },
            },
            stake_blue={
                name="Pozo azul",
                text={
                    "La tienda puede tener comodines {C:attention}perecederos{}",
                    "{C:inactive,s:0.8}(Debilitados luego de 5 rondas)",
                    "{s:0.8}Se aplica a todos los pozos anteriores",
                },
            },
            stake_gold={
                name="Pozo de oro",
                text={
                    "El interés requiere {C:money}$6", -- Texto actualizado
                    "{C:inactive,s:0.8}(en lugar de {C:money}$5{C:inactive,s:0.8})", -- Texto actualizado
                    "El último ante es {C:attention}9", -- Added text
                    "{s:0.8}Aplica en todas las apuestas anteriores",
                },
            },
            stake_green={
                name="Pozo verde",
                text={
                    "Escalas de puntos requeridas más rápidas",
                    "para cada {C:attention}apuesta inicial",
                    "{s:0.8}Se aplica a todos los pozos anteriores",
                },
            },
            stake_orange={
                name="Pozo naranja",
                text={
                    "La tienda puede tener comodines {C:attention}de alquiler{}",
                    "{C:inactive,s:0.8}(Cuesta {C:money,s:0.8}3 ${C:inactive,s:0.8} por ronda)",
                    "{s:0.8}Aplica en todas las apuestas anteriores",
                },
            },
            stake_purple={
                name="Pozo morado",
                text={
                    "Escalas de puntos requeridas más rápidas",
                    "para cada {C:attention}apuesta inicial",
                    "{s:0.8}Se aplica a todos los pozos anteriores",
                },
            },
            stake_red={
                name="Pozo rojo",
                text={
                    "La {C:attention}ciega pequeña{} no otorga",
                    "ninguna recompensa monetaria",
                    "{s:0.8}Se aplica a todos los pozos anteriores",
                },
            },
            stake_white={
                name="Pozo blanco",
                text={
                    "Dificultad básica",
                },
            },
        },
    }
}
