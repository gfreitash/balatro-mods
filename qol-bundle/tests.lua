-- qol-bundle/tests.lua
-- Integration tests for QoL Bundle (run via BalatroIntegration).
--
-- Suite loader: holds the shared helpers passed to every group file under
-- tests/, snapshots/restores the mod config around the whole suite, and keeps
-- every test starting from a deterministic baseline.
--
-- IMPORTANT lifecycle notes:
--  * Most features are applied through SMODS take_ownership gated by config at
--    mod load. Tests re-apply a feature at runtime via T.apply_feature (the
--    getters are idempotent); centers are snapshotted on first touch and
--    restored between tests and at suite end, so nothing leaks into later
--    suites (BalatroIntegration teardown re-injects SMODS objects).
--  * Rarity POOLS are only rebuilt at boot, so tests must assert center fields,
--    never G.P_JOKER_RARITY_POOLS membership.
--  * A failed assert abandons the test coroutine, so center cleanup on failure
--    runs from the test_fail event (T.recover_case).
--
-- Loaded from src/init.lua only when the Integration framework is installed;
-- excluded from ThunderStore packages by the build script.
-- Test names are namespaced with `riosodu/` so the repo test runner can select
-- just this repo's tests.

if not BInt then
	return
end

local T = {}

-- ---------------------------------------------------------------------------
-- Config keys and shipped defaults (qol-bundle/config.lua)
-- ---------------------------------------------------------------------------

T.DEFAULTS = {
	joker_max_enabled = true,
	joker_max_value = 3,
	hit_the_road_joker_enabled = true,
	square_joker_enabled = true,
	wildcard_fix_enabled = true,
	wheel_of_fortune_enabled = true,
	wheel_of_fortune_value = 3,
	eight_ball_joker_enabled = true,
	eight_ball_joker_value = 3,
	space_joker_enabled = false,
	space_joker_value = 3,
	steel_joker_enabled = false,
	unweighted_editions_enabled = false,
	flower_pot_wildcard_enabled = true,
	baron_uncommon_enabled = true,
	mime_rare_enabled = true,
	dna_uncommon_enabled = false,
	pareidolia_common_enabled = false,
	nerf_hanging_chad_enabled = true,
	satellite_joker_enabled = true,
	sigil_control_enabled = true,
	ouija_control_enabled = true,
	spectral_seal_clip_enabled = false,
	loyalty_card_scaling_enabled = false,
	splash_joker_retrigger_enabled = true,
	ceremonial_dagger_common_enabled = true,
	mail_in_rebate_uncommon_enabled = true,
	fortune_teller_cheaper_enabled = true,
	erosion_xmult_enabled = true,
	interest_on_skip_enabled = true,
	enhanced_magic_trick_enabled = true,
	new_illusion_enabled = true,
	castle_checkered_enabled = true,
	marble_joker_xchips_enabled = true,
	stone_joker_mult_enabled = true,
	seance_rework_enabled = false,
	caino_rework_enabled = false,
	onyx_agate_enabled = false,
	planet_merchant_rework_enabled = false,
	wraith_rework_enabled = false,
	ankh_rework_enabled = false,
	lovers_two_cards_enabled = false,
	hex_rework_enabled = false,
	matador_rework_enabled = false,
	red_card_rework_enabled = false,
	bull_buff_enabled = false,
	mr_bones_rework_enabled = false,
	yorick_multiplier_enabled = true,
	yorick_multiplier_value = 1.5,
}

T.CONFIG_KEYS = {}
for key, _ in pairs(T.DEFAULTS) do
	table.insert(T.CONFIG_KEYS, key)
end
table.sort(T.CONFIG_KEYS)

-- ---------------------------------------------------------------------------
-- Center snapshot/restore (runtime take_ownership support)
-- ---------------------------------------------------------------------------

local CENTER_FIELDS = {
	"config",
	"calculate",
	"calc_dollar_bonus",
	"loc_vars",
	"rarity",
	"cost",
	"enhancement_gate",
	"update",
	"taken_ownership",
	"is_loc_modified",
	"generate_ui",
	"mod",
}

local center_snapshots = {}
local active_centers = {}

--- Snapshots a center the first time a test touches it (original state wins).
function T.snap_center(key)
	if not center_snapshots[key] then
		local center = G.P_CENTERS[key]
		if not center then
			return nil
		end
		local snap = {}
		for _, field in ipairs(CENTER_FIELDS) do
			snap[field] = center[field]
		end
		center_snapshots[key] = snap
	end
	active_centers[key] = true
	return center_snapshots[key]
end

--- Restores a center to its first snapshot.
function T.restore_center(key)
	local snap = center_snapshots[key]
	local center = G.P_CENTERS[key]
	if not snap or not center then
		return
	end
	for _, field in ipairs(CENTER_FIELDS) do
		center[field] = snap[field]
	end
end

--- Restores every center touched during the current test.
function T.restore_active_centers()
	for key, _ in pairs(active_centers) do
		T.restore_center(key)
	end
	active_centers = {}
end

--- Sets the feature's config flag, re-applies it through the mod's getter and
--- remembers the center for automatic restore.
---
--- take_ownership dereferences SMODS.current_mod when the target already has a
--- `mod` field (game_object.lua:259) and that global is only set while mods are
--- loading; inject QOL_BUNDLE.mod around the call so runtime re-application
--- works.
function T.apply_feature(config_key, center_key, getter)
	if config_key then
		QOL_BUNDLE.config[config_key] = true
	end
	if center_key then
		T.snap_center(center_key)
	end
	if type(getter) == "function" then
		local prev_mod = SMODS.current_mod
		SMODS.current_mod = QOL_BUNDLE.mod
		local ok, err = pcall(getter)
		SMODS.current_mod = prev_mod
		if not ok then
			error(err)
		end
	end
	return center_key and G.P_CENTERS[center_key] or nil
end

-- ---------------------------------------------------------------------------
-- Config helpers
-- ---------------------------------------------------------------------------

local live_config_snapshot = nil

function T.reset_config()
	for key, value in pairs(T.DEFAULTS) do
		QOL_BUNDLE.config[key] = value
	end
end

function T.set_config(overrides)
	for key, value in pairs(overrides or {}) do
		QOL_BUNDLE.config[key] = value
	end
end

-- ---------------------------------------------------------------------------
-- Per-test baseline / failure recovery
-- ---------------------------------------------------------------------------

function T.begin_case()
	T.restore_active_centers()
	T.reset_config()
end

function T.recover_case()
	T.restore_active_centers()
	T.reset_config()
end

-- The PB tests come from this same loader (registered as riosodu/pb/...), so
-- they need the same per-test baseline and failure recovery as the main tests.
local function is_qol_test(name)
	return name:find("riosodu/qol_bundle", 1, true) ~= nil
		or name:find("riosodu/pb", 1, true) ~= nil
end

BInt.on("test_start", function(name)
	if is_qol_test(name) then
		T.begin_case()
	end
end)

BInt.on("test_fail", function(name)
	if is_qol_test(name) then
		T.recover_case()
	end
end)

BInt.on("suite_start", function()
	live_config_snapshot = {}
	local differs = {}
	for _, key in ipairs(T.CONFIG_KEYS) do
		live_config_snapshot[key] = QOL_BUNDLE.config[key]
		if QOL_BUNDLE.config[key] ~= T.DEFAULTS[key] then
			table.insert(differs, key)
		end
	end
	-- The launch config may legitimately differ from the shipped defaults (the
	-- save persists user choices). Tests are written against the DEFAULTS forced
	-- by begin_case, and features are always re-applied explicitly, so runs are
	-- deterministic either way; this note just explains surprising load state.
	if #differs > 0 then
		RIOSODU_SHARED.utils.sendDebugMessage(
			"qol_bundle tests: launch config differs from defaults for: " .. table.concat(differs, ", "),
			QOL_BUNDLE.mod_id
		)
	end
end)

BInt.on("suite_complete", function()
	if live_config_snapshot then
		for key, value in pairs(live_config_snapshot) do
			QOL_BUNDLE.config[key] = value
		end
		live_config_snapshot = nil
	end
	for key, _ in pairs(center_snapshots) do
		T.restore_center(key)
	end
	active_centers = {}
end)

-- ---------------------------------------------------------------------------
-- Shared test helpers
-- ---------------------------------------------------------------------------

--- Starts a run at the given stake (stake defaults to 1).
function T.start_run(test, seed, stake, deck)
	local opts = { seed = seed, stake = stake or 1 }
	if deck then
		opts.deck = deck
	end
	test:start_run(opts)
	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)
end

--- Wins the current blind deterministically (see rebalanced-stakes suite):
--- plays the last remaining hand with the required chips at 1.
function T.win_round(test, money)
	if money then
		test:set_money(money)
	end
	test:set_hands(1)
	G.GAME.blind.chips = 1
	test:highlight({ 1, 2, 3, 4, 5 }):assert()
	test:play_hand():assert()
end

--- Total dollars earned for the round that just ended.
function T.round_dollars(test, timeout)
	BInt._wait.for_condition(function()
		return G.GAME.current_round.dollars ~= nil
	end, timeout or 30, "Timeout waiting for round evaluation to finish")
	return G.GAME.current_round.dollars
end

--- Direct calculate probe: runs the SMods center-injected calculate path.
function T.calc(card, context)
	return card:calculate_joker(context)
end

--- Forces a hand card to a specific rank/suit (id like "S_A", "H_2").
function T.force_card(index, id)
	local card = G.hand.cards[index]
	if card then
		card:set_base(G.P_CARDS[id])
	end
	return card
end

--- Removes a deck card safely. BInt's remove_playing_card corrupts G.playing_cards
--- (Card:remove already removes the card by identity; BInt's extra table.remove(i)
--- then drops a neighbor from the registry).
function T.remove_deck_card(id)
	local parsed = BInt._resolve.parse_card_id(id)
	if not parsed then
		return false
	end
	for _, card in ipairs(G.playing_cards) do
		if card.base.value == parsed.rank and card.base.suit == parsed.suit then
			card:remove()
			return true
		end
	end
	return false
end

--- Skips the current blind without acquiring a tag (money deltas stay clean).
function T.manual_skip()
	G.FUNCS.skip_blind({ UIBox = { get_UIE_by_ID = function() return nil end } })
end

--- Re-runs every on_game_start hook, which applies the content files'
--- config-dependent localization closures.
function T.refresh_loc()
	for _, hook in ipairs(RIOSODU_SHARED.hooks.on_game_start) do
		hook()
	end
end

--- Shape-agnostic search through a localized text table.
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

function T.hand_limit()
	return G.hand and G.hand.config.card_limit or nil
end

--- Raw stake/loc description text for other sets (used by localization tests).
function T.loc_text(set, key)
	local entry = G.localization.descriptions[set] and G.localization.descriptions[set][key]
	return entry and entry.text or nil
end

T.PB = PB_UTIL ~= nil and PB_UTIL.light_suits ~= nil

-- ---------------------------------------------------------------------------
-- Load the per-group test files
-- ---------------------------------------------------------------------------

local FILES = {
	"tests/loader.lua",
	"tests/interest_skip.lua",
	"tests/shop_size.lua",
	"tests/jokers_rarity_cost.lua",
	"tests/jokers_scaling.lua",
	"tests/jokers_economy.lua",
	"tests/jokers_scoring.lua",
	"tests/jokers_beta.lua",
	"tests/spectrals_control.lua",
	"tests/spectrals_enhanced.lua",
	"tests/spectral_reworks.lua",
	"tests/tarots.lua",
	"tests/vouchers.lua",
	"tests/overrides.lua",
	"tests/localization.lua",
	"tests/hit_the_road_repro.lua",
	"tests/fix_regressions.lua",
	"tests/pb_compat.lua",
}

for _, file in ipairs(FILES) do
	local chunk = SMODS.load_file(file, QOL_BUNDLE.mod_id)
	if not chunk then
		RIOSODU_SHARED.utils.sendDebugMessage("Failed to load test file: " .. file)
	else
		local register = chunk()
		if type(register) == "function" then
			register(T)
		end
	end
end
