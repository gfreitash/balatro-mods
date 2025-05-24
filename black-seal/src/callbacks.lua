G.FUNCS.bsm_calculate_and_set_seal_weights = BSM.utils.calculate_and_set_seal_weights

BSM.utils.seal_count = function ()
    local count = 0
    for key, value in pairs(G.P_SEALS) do count = count + 1 end
    return count
end