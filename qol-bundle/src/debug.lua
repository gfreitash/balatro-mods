-- qol-bundle/src/debug.lua

QOL_BUNDLE.debug = QOL_BUNDLE.debug or {}

function QOL_BUNDLE.debug.test_poll_edition(num_calls, guaranteed_edition)
    num_calls = num_calls or 10000
    local results = {
        foil = 0,
        holo = 0,
        polychrome = 0,
        negative = 0,
        none = 0
    }

    RIOSODU_SHARED.utils.sendDebugMessage("Starting poll_edition test with " .. num_calls .. " calls (guaranteed_edition: " .. tostring(guaranteed_edition) .. ")...")

    for i = 1, num_calls do
        local edition = poll_edition('test_key_' .. i, 1, false, guaranteed_edition)
        if edition then
            if edition.foil then
                results.foil = results.foil + 1
            elseif edition.holo then
                results.holo = results.holo + 1
            elseif edition.polychrome then
                results.polychrome = results.polychrome + 1
            elseif edition.negative then
                results.negative = results.negative + 1
            end
        else
            results.none = results.none + 1
        end
    end

    RIOSODU_SHARED.utils.sendDebugMessage("--- poll_edition Test Results ---")
    RIOSODU_SHARED.utils.sendDebugMessage("Total Calls: " .. num_calls)
    for k, v in pairs(results) do
        local percentage = string.format("%.2f", (v / num_calls) * 100)
        RIOSODU_SHARED.utils.sendDebugMessage(string.format("%s: %d (%.2f%%)", k, v, percentage))
    end
    RIOSODU_SHARED.utils.sendDebugMessage("---------------------------------")
end

function QOL_BUNDLE.debug.register_debug_keybinds()
    RIOSODU_SHARED.debug.register_keybind(QOL_BUNDLE.mod_id, {
        key_pressed = 'f11',
        name = 'test_unweighted_editions',
        desc = 'Test Unweighted Editions (10000 polls)',
        action = function() QOL_BUNDLE.debug.test_poll_edition(10000, true) end
    })
end
