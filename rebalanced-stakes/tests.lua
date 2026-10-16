-- rebalanced-stakes/tests.lua
-- Integration tests for Rebalanced Stakes (run via BalatroIntegration).
--
-- Suite loader: holds the shared helpers passed to every group file under
-- tests/. The mod has no configuration options, so unlike other suites there
-- is nothing to snapshot/restore around the run.
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
-- Helpers shared with the group files (passed as `T` to each register function)
-- ---------------------------------------------------------------------------

--- Starts a run at the given stake.
function T.start_run_at_stake(test, seed, stake)
	test:start_run({ seed = seed, stake = stake })
	test:assert_eq(G.GAME.stake, stake, "run should start at stake " .. stake)
	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)
end

--- Wins the current blind deterministically: drops the required chips to 1
--- and plays a single 5-card hand (the last remaining hand, so there is no
--- unused-hands bonus). Leaves the game in ROUND_EVAL, with end_round()
--- already executed. Optionally sets the player's money first.
function T.win_round(test, money)
	if money then
		test:set_money(money)
	end
	test:set_hands(1)
	G.GAME.blind.chips = 1
	test:highlight({ 1, 2, 3, 4, 5 }):assert()
	test:play_hand():assert()
end

--- Total dollars earned for the round that just ended. Only set once the
--- round-evaluation UI finished adding its rows; do not confuse with
--- `cash_out()`, which drains this value.
function T.round_dollars(test, timeout)
	BInt._wait.for_condition(function()
		return G.GAME.current_round.dollars ~= nil
	end, timeout or 30, "Timeout waiting for round evaluation to finish")
	return G.GAME.current_round.dollars
end

--- Raw localization text for a stake description (e.g. "stake_blue").
function T.stake_loc(key)
	local entry = G.localization.descriptions.Stake and G.localization.descriptions.Stake[key]
	return entry and entry.text or nil
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
-- Load the per-group test files
-- ---------------------------------------------------------------------------

local FILES = {
	"tests/stakes.lua",
	"tests/interest.lua",
	"tests/perishable.lua",
	"tests/shop_stickers.lua",
	"tests/win_ante.lua",
	"tests/localization.lua",
}

for _, file in ipairs(FILES) do
	local chunk = SMODS.load_file(file, RSM.mod_id)
	if not chunk then
		RIOSODU_SHARED.utils.sendDebugMessage("Failed to load test file: " .. file)
	else
		local register = chunk()
		if type(register) == "function" then
			register(T)
		end
	end
end
