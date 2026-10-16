-- tools/integration-runner/main.lua
-- Local-only harness that auto-runs BalatroIntegration test suites.
--
-- scripts/run-integration-tests.sh installs this mod and writes a marker file,
-- run_tests.txt, next to this file:
--
--   pattern=riosodu     -- test-name substring to run (empty/absent = all)
--   quit=1              -- quit the game once the suite finishes (0 = stay open)
--   token=run-...       -- optional run handshake: echoed into the results file
--
-- For marker-initiated runs the harness also appends per-test results
-- ("test=<name>\t<pass|fail>") to results/latest.txt, which the runner script
-- turns into machine-readable test evidence (see scripts/lib/test-evidence.sh).
--
-- The marker is polled continuously: a fresh launch picks it up on boot, and
-- while the game is running new markers re-trigger suites in the live session
-- (used by the runner script's --attach mode for fast iteration). A pending
-- request waits until the main menu is reached and no suite is in progress.

local runner = SMODS.current_mod
local MOD_PATH = runner.path
local MARKER = MOD_PATH .. "run_tests.txt"
local POLL_INTERVAL = 0.5

if not BInt then
	sendWarnMessage("BalatroIntegration (BInt) is not loaded; harness disabled.", runner.id)
	return
end

-- Unlock/discovery notifications are queued per-profile (unlock_notify.jkr) and
-- replayed as pausing full-screen overlays on the splash/menu. Content from
-- test-only libs (e.g. Paperback) can queue a whole batch at boot, which stalls
-- suite startup. This harness only exists in the local test environment, so
-- silence the notification pipeline for the whole session and drop any queue
-- that is already waiting.
unlock_notify = function() end
create_unlock_overlay = function() end

local function clear_unlock_notify_queue()
	local profile = G.SETTINGS and G.SETTINGS.profile
	if profile then
		pcall(function()
			love.filesystem.remove(profile .. "/unlock_notify.jkr")
		end)
	end
end

clear_unlock_notify_queue()

local function read_marker()
	local ok, info = pcall(NFS.getInfo, MARKER)
	if not ok or not info then return nil end
	local read_ok, contents = pcall(NFS.read, MARKER)
	NFS.remove(MARKER)
	if not read_ok then return nil end
	return contents
end

local function parse_marker(contents)
	local pattern, quit_after, token = nil, true, nil
	for line in contents:gmatch("[^\r\n]+") do
		local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if key == "pattern" then
			pattern = (value ~= "" and value) or nil
		elseif key == "quit" then
			quit_after = not (value == "0" or value:lower() == "false")
		elseif key == "token" then
			token = (value ~= "" and value) or nil
		end
	end
	return pattern, quit_after, token
end

local function can_run()
	return G.STAGE == G.STAGES.MAIN_MENU
		and G.STATE == G.STATES.MENU
		and not BInt._running
		and BInt._active_coroutine == nil
end

local function count_matching(pattern)
	local n = 0
	for _, test in ipairs(BInt._tests) do
		if not pattern or test.name:find(pattern, 1, true) then
			n = n + 1
		end
	end
	return n
end

local pending = nil        -- { pattern = string|nil, quit = boolean, token = string|nil }
local current_quit = false -- marker's quit flag for the running/finished suite
local current_token = nil  -- marker's run token, echoed into the results file
local current_tests = nil  -- per-test results for the current marker-initiated run
local quit_requested = false
local quit_deadline = nil
local poll_timer = 0

-- Pick up a marker that was already there when this mod loaded (fresh launch).
do
	local contents = read_marker()
	if contents then
		clear_unlock_notify_queue()
		local pattern, quit_after, token = parse_marker(contents)
		pending = { pattern = pattern, quit = quit_after, token = token }
	end
end

-- Collect per-test results for marker-initiated runs so the runner script can
-- record machine-readable test evidence.
BInt.on("suite_start", function()
	if current_token then current_tests = {} end
end)
BInt.on("test_pass", function(name)
	if current_tests then
		current_tests[#current_tests + 1] = { name = name, passed = true }
	end
end)
BInt.on("test_fail", function(name)
	if current_tests then
		current_tests[#current_tests + 1] = { name = name, passed = false }
	end
end)

-- Append the per-test results and the run token to the results file (BInt
-- writes it just before this event fires) so the runner script can tell this
-- suite's results apart from a stale suite finishing late (e.g. an interrupted
-- attach run).
local function echo_run_token()
	if not current_token then return end
	local results_path = BInt._MOD_METADATA.path .. "results/latest.txt"
	local ok = pcall(function()
		local contents = NFS.read(results_path) or ""
		local file = NFS.newFile(results_path)
		file:open("w")
		file:write(contents)
		if contents ~= "" and contents:sub(-1) ~= "\n" then
			file:write("\n")
		end
		if current_tests then
			for _, result in ipairs(current_tests) do
				file:write("test=" .. result.name .. "\t" .. (result.passed and "pass" or "fail") .. "\n")
			end
			current_tests = nil
		end
		file:write("run_token=" .. current_token .. "\n")
		file:close()
	end)
	if not ok then
		sendWarnMessage("[integration-runner] could not echo the run token to the results file", runner.id)
	end
end

BInt.on("suite_complete", function()
	echo_run_token()
	current_token = nil
	if current_quit then quit_requested = true end
end)
local base_update = Game.update
function Game:update(dt)
	base_update(self, dt)

	-- Skip the intro splash screen when a suite is pending, so tests start
	-- immediately instead of waiting for (or needing input to skip) the intro.
	-- Same code path as pressing right-click / Start on the splash screen.
	if pending and G.STATE == G.STATES.SPLASH then
		G:delete_run()
		G:main_menu()
	end

	-- Poll for new suite requests while idle.
	if not quit_requested and not pending then
		poll_timer = poll_timer + dt
		if poll_timer >= POLL_INTERVAL then
			poll_timer = 0
			local contents = read_marker()
			if contents then
				clear_unlock_notify_queue()
				local pattern, quit_after, token = parse_marker(contents)
				pending = { pattern = pattern, quit = quit_after, token = token }
			end
		end
	end

	-- Start a pending suite once the game is settled at the main menu.
	if pending and can_run() then
		local req = pending
		pending = nil
		local matches = count_matching(req.pattern)
		if matches == 0 then
			sendWarnMessage(("[integration-runner] no tests match pattern '%s' (%d registered)"):format(req.pattern or "", #BInt._tests), runner.id)
			if req.quit then quit_requested = true end
		else
			sendDebugMessage(("[integration-runner] starting %d test(s) matching '%s'"):format(matches, req.pattern or "<all>"), runner.id)
			current_quit = req.quit
			current_token = req.token
			BInt.run_tests(req.pattern)
		end
	end

	if quit_requested then
		quit_deadline = quit_deadline or (G.TIMERS.REAL + 30)
		-- Wait for the framework to restore the original profile before quitting.
		local idle = (not BInt._running) and (BInt._active_coroutine == nil)
		if idle or G.TIMERS.REAL > quit_deadline then
			quit_requested = false
			sendDebugMessage("[integration-runner] quitting", runner.id)
			love.event.quit()
		end
	end
end
