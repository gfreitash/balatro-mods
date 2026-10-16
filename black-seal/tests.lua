-- black-seal/tests.lua
-- Integration tests for the Black Seal (run via BalatroIntegration).
--
-- This file is the suite loader: it holds the shared helpers passed to every
-- group file under tests/, snapshots/restores the mod config around the whole
-- suite, and wires everything through BInt.
--
-- Loaded from src/init.lua only when the Integration framework is installed;
-- excluded from ThunderStore packages by the build script.
-- Test names are namespaced with `riosodu/` so the repo test runner can select
-- just this repo's tests.

if not BInt then
	return
end

local T = {}

T.SEAL = BSM.black_seal_id_full

local CONFIG_KEYS = {
	"black_seal_percentage",
	"retrigger_black_seal",
	"keep_seals_in_hand",
	"override_ectoplasm_effect",
	"ectoplasm_override_reduces_hand",
}

-- ---------------------------------------------------------------------------
-- Helpers shared with the group files (passed as `T` to each register function)
-- ---------------------------------------------------------------------------

--- Applies the given config values, then refreshes the derived state the mod
--- keeps in sync (seal weights and the config-dependent localization texts).
--- Keys missing from `overrides` are left untouched.
function T.set_config(overrides)
	for _, key in ipairs(CONFIG_KEYS) do
		if overrides[key] ~= nil then
			BSM.config[key] = overrides[key]
		end
	end
	BSM.utils.calculate_and_set_seal_weights()
	BSM.utils.update_black_seal_text()
	BSM.utils.update_ectoplasm_text()
end

--- Deterministic config for tests that start runs: no randomly spawned Black
--- Seals, everything else at the shipped defaults unless overridden.
function T.prep_run(overrides)
	local cfg = {
		black_seal_percentage = 0,
		retrigger_black_seal = true,
		keep_seals_in_hand = true,
		override_ectoplasm_effect = true,
		ectoplasm_override_reduces_hand = true,
	}
	for key, value in pairs(overrides or {}) do
		cfg[key] = value
	end
	T.set_config(cfg)
end

function T.count_seals(cards, seal_key)
	local n = 0
	for _, card in ipairs(cards) do
		if card.seal == (seal_key or T.SEAL) then
			n = n + 1
		end
	end
	return n
end

function T.negative_joker_count(test)
	local n = 0
	for _, joker in ipairs(test:get_jokers()) do
		if joker.edition and joker.edition.negative then
			n = n + 1
		end
	end
	return n
end

--- Direct state setup: seals the first card currently sitting in the deck
--- (i.e. not in hand) so deck-wide seal removal can be observed.
function T.seal_deck_card()
	local card = G.deck and G.deck.cards and G.deck.cards[1]
	if not card then
		return nil
	end
	card:set_seal(T.SEAL, true, true)
	return card
end

function T.hand_limit()
	return G.hand and G.hand.config.card_limit or nil
end

--- Shape-agnostic search through a localized text table (localize() output
--- shape varies between game versions, so probe for strings instead).
function T.loc_contains(text, needle)
	if type(text) == "string" then
		return text:find(needle, 1, true) ~= nil
	elseif type(text) == "table" then
		for _, value in pairs(text) do
			if T.loc_contains(value, needle) then
				return true
			end
		end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Suite lifecycle: snapshot/restore the mod config around the whole suite
-- ---------------------------------------------------------------------------

local original_config = nil

BInt.on("suite_start", function()
	original_config = {}
	for _, key in ipairs(CONFIG_KEYS) do
		original_config[key] = BSM.config[key]
	end
	-- Deterministic default for tests that do not set their own percentage.
	T.set_config({ black_seal_percentage = 0 })
end)

BInt.on("suite_complete", function()
	if original_config then
		T.set_config(original_config)
		original_config = nil
	end
end)

-- ---------------------------------------------------------------------------
-- Load the per-group test files
-- ---------------------------------------------------------------------------

local FILES = {
	"tests/core.lua",
	"tests/retrigger.lua",
	"tests/weights.lua",
	"tests/ectoplasm.lua",
	"tests/localization.lua",
}

for _, file in ipairs(FILES) do
	local chunk = SMODS.load_file(file, BSM.mod_id)
	if not chunk then
		RIOSODU_SHARED.utils.sendDebugMessage("Failed to load test file: " .. file)
	else
		local register = chunk()
		if type(register) == "function" then
			register(T)
		end
	end
end
