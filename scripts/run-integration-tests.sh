#!/usr/bin/env bash
#
# Runs BalatroIntegration test suites inside a real Balatro session.
#
# Modes:
#   launch (default)   Builds a CLEAN Mods folder for the run: backs up what it
#                      will wipe (Mods entries + the save dir's config/), wipes
#                      everything managed (lovely/ is preserved), installs the
#                      declared mods + harness infrastructure, launches Balatro
#                      via Steam, waits for the suite results and reports them.
#                      The backup is restored by --teardown, or manually via
#                      scripts/test-mods.sh teardown.
#   --pb               PB mode: adds the test-only Paperback library (pinned
#                      Thunderstore spec) and, unless a pattern is given, runs
#                      the reduced PB scope (default pattern "riosodu/pb").
#                      Keep PB and non-PB runs separate: PB must not affect
#                      unrelated tests, and both compat branches stay exercised.
#   --attach           The game is already running (launched once with
#                      --keep-open): skips setup/launch and re-runs the selected
#                      tests in the live session via the harness marker. The
#                      mod set is frozen at boot (see the session stamp printed
#                      on attach). Iterations take seconds instead of a full
#                      boot; pass --close-on-finish to close it when done.
#
# Window handling (GNOME Wayland): the game window must be mapped and visible
# on the active workspace during a run, otherwise the compositor throttles the
# game loop to ~1 fps and suites crawl. Parked (minimized) between runs.
#
# Usage:
#   scripts/run-integration-tests.sh [options] [pattern]
#
# Arguments:
#   pattern            Only run tests whose name contains this substring
#                      (default: riosodu).
#
# Options:
#   --mods SPEC[,SPEC] Content mods for the run (repeatable). Replaces the
#                      default set (all local repo mods); 'none' = infra only.
#                      Specs: local:<dir> | thunderstore:<ns>-<name>[@<ver>] |
#                             github:<owner>/<repo>[@<ref>][::<subdir>] |
#                             github-release:<owner>/<repo>@<tag>#<asset>
#   --pb               Adds thunderstore:PaperbackedProjects-Paperback@<pin>
#                      (PAPERBACK_VERSION, default 0.9.1) and switches the
#                      default pattern to riosodu/pb. Launch mode only.
#   --refresh-mods     Re-resolve / re-download instead of using the cache.
#   --offline          Resolve from the cache only (no network).
#   --dry-run          Print the setup plan (no writes, no launch) and exit.
#   --teardown         After the run: close the game, then restore the pending
#                      backup exactly (Mods entries + config/). Conflicts with
#                      --keep-open.
#   --attach           Re-run tests in an already-running game (fast iteration).
#   --close-on-finish  Close the game as soon as the suite results are written.
#   --timeout SECS     Max seconds to wait for results (default: 900).
#   --keep-open        Leave the game running after the suite finishes
#                      (implicit in --attach).
#   --keep-visible     Don't minimize (park) the game windows after the run.
#   --no-sync          Skip the Mods-folder setup; use the folder as-is.
#   -h, --help         Show this help.
#
# Exit codes:
#   0 all tests passed; 1 failures/timeout/errors; 2 invalid usage.
#
# Notes:
#   - --attach does not hot-reload mod/test code; file changes need a relaunch.
#   - Mod-affecting flags (--mods/--pb/--refresh-mods/--offline/--dry-run) are
#     rejected with --attach: the mod set is frozen when the session launches.
#   - Backups live in lib/mod_folder_snapshots/ (gitignored); see
#     scripts/test-mods.sh (plan|setup|teardown|clean|status|prune).

set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info()    { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn()    { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error()   { echo -e "${C_RED}ERROR: $1${C_NC}" >&2; }

usage() {
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/mods.sh
source "$SCRIPT_DIR/lib/mods.sh"
# shellcheck source=lib/test-evidence.sh
source "$SCRIPT_DIR/lib/test-evidence.sh"

INTEGRATION_SRC="$REPO_ROOT/lib/BalatroIntegration"
HARNESS_SRC="$REPO_ROOT/tools/integration-runner"
X11_HELPER="$SCRIPT_DIR/x11_window.py"

PATTERN="riosodu"
PATTERN_SET=0
TIMEOUT=900
KEEP_OPEN=0
KEEP_VISIBLE=0
DO_SYNC=1
ATTACH=0
CLOSE_ON_FINISH=0
PB_MODE=0
DRY_RUN=0
TEARDOWN=0
MODS_SET=0
MODS_REFRESH=0
MODS_OFFLINE=0
declare -a MODS_SPECS=()

# --- Argument parsing ---
while [ $# -gt 0 ]; do
    case "$1" in
        --attach)       ATTACH=1; shift ;;
        --close-on-finish) CLOSE_ON_FINISH=1; shift ;;
        --timeout)      TIMEOUT="${2:?--timeout requires a value}"; shift 2 ;;
        --keep-open)    KEEP_OPEN=1; shift ;;
        --keep-visible) KEEP_VISIBLE=1; shift ;;
        --no-sync)      DO_SYNC=0; shift ;;
        --pb)           PB_MODE=1; shift ;;
        --mods)
            IFS=',' read -r -a _mods_split <<< "${2:?--mods requires a value}"
            MODS_SPECS+=("${_mods_split[@]}")
            MODS_SET=1
            shift 2 ;;
        --refresh-mods) MODS_REFRESH=1; shift ;;
        --offline)      MODS_OFFLINE=1; shift ;;
        --dry-run)      DRY_RUN=1; shift ;;
        --teardown)     TEARDOWN=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        -*)             log_error "Unknown option: $1"; exit 2 ;;
        *)              PATTERN="$1"; PATTERN_SET=1; shift ;;
    esac
done

if [ "$PB_MODE" = 1 ]; then
    MODS_SPECS+=("thunderstore:PaperbackedProjects-Paperback@${PAPERBACK_VERSION:-0.9.1}")
    if [ "$PATTERN_SET" = 0 ]; then
        PATTERN="riosodu/pb"
    fi
fi

# '--mods none' (alone or alongside --pb) removes the content-mod entries.
if [ "$MODS_SET" = 1 ]; then
    _filtered=()
    for _s in "${MODS_SPECS[@]}"; do
        [ "$_s" = "none" ] || _filtered+=("$_s")
    done
    MODS_SPECS=("${_filtered[@]}")
fi

MODS_TOUCHING=0
if [ "$PB_MODE" = 1 ] || [ "$MODS_SET" = 1 ] || [ "$MODS_REFRESH" = 1 ] || [ "$MODS_OFFLINE" = 1 ] || [ "$DRY_RUN" = 1 ]; then
    MODS_TOUCHING=1
fi

if [ "$ATTACH" = 1 ] && [ "$MODS_TOUCHING" = 1 ]; then
    log_warn "Mod-affecting flags (--mods, --pb, --refresh-mods, --offline, --dry-run) only apply to launch mode; --attach uses the running session's load state."
    exit 2
fi

if [ "$TEARDOWN" = 1 ] && [ "$KEEP_OPEN" = 1 ]; then
    log_error "--teardown closes the game to restore the pre-session state; it conflicts with --keep-open."
    exit 2
fi

if [ "$DO_SYNC" = 0 ] && [ "$MODS_TOUCHING" = 1 ]; then
    log_error "--no-sync cannot be combined with mod-affecting flags (--mods, --pb, --refresh-mods, --offline, --dry-run)."
    exit 2
fi

# --- Prerequisite checks ---
check_prerequisites() {
    local missing=0
    local tools=(rsync curl unzip jq git python3 wmctrl xprop)
    [ "$ATTACH" = 0 ] && tools+=(steam)
    for tool in "${tools[@]}"; do
        command -v "$tool" >/dev/null 2>&1 || { log_error "Required tool '$tool' is not installed."; missing=1; }
    done
    [ "$missing" = 0 ] || exit 1

    if [ ! -d "$INTEGRATION_SRC/.git" ]; then
        log_error "BalatroIntegration not found at $INTEGRATION_SRC. Run ./setup-libs.sh first."
        exit 1
    fi
    if [ ! -f "$HARNESS_SRC/main.lua" ]; then
        log_error "Harness mod not found at $HARNESS_SRC."
        exit 1
    fi
}

game_running() {
    pgrep -f 'Balatro\.exe' >/dev/null 2>&1
}

# Finds the Balatro Mods directory (same logic as sync-mods.sh)
determine_destination() {
    local link_path="$REPO_ROOT/lib/mod_folder"
    local default_mods_path="$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"

    if [ -L "$link_path" ]; then
        readlink -f "$link_path"
    elif [ -d "$default_mods_path" ]; then
        echo "$default_mods_path"
    else
        echo ""
    fi
}

# --- Window handling ---
# NOTE: every helper must be tolerant of missing WM info: some GNOME sessions
# do not export _NET_CURRENT_DESKTOP, which makes `wmctrl -d` fail, and with
# `set -o pipefail` a bare failing pipeline would abort the whole run.
game_wids() {
    wmctrl -lx 2>/dev/null | grep -i 'steam_app_2379780' | awk '{print $1}' || true
}

balatro_wid() {
    wmctrl -lx 2>/dev/null | grep -i 'steam_app_2379780' | grep -v 'Lovely' | head -n1 | awk '{print $1}' || true
}

active_desktop() {
    wmctrl -d 2>/dev/null | awk '$2=="*"{print $1; exit}' || true
}

window_state() {
    xprop -id "$1" WM_STATE 2>/dev/null | grep -o 'window state: [A-Za-z]*' || true
}

window_desktop() {
    wmctrl -l 2>/dev/null | awk -v w="$1" '$1==w{print $2; exit}' || true
}

# Minimize the transient Steam "Launching..." popup so it does not flash on
# screen. The game windows themselves stay visible: minimized/occluded windows
# make the compositor throttle the game loop to ~1 fps.
minimize_steam_popup() {
    local deadline=$(( $(date +%s) + 45 ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        [ -n "$(balatro_wid)" ] && return 0
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            local wid cls title
            wid=$(awk '{print $1}' <<<"$line")
            cls=$(awk '{print $3}' <<<"$line")
            title=$(awk '{$1="";$2="";$3="";$4="";sub(/^ +/,"");print}' <<<"$line")
            if [[ "$cls" == *steamwebhelper* && "$title" == *Launching* ]]; then
                python3 "$X11_HELPER" iconify "$wid" >/dev/null 2>&1 || true
            fi
        done < <(wmctrl -lx 2>/dev/null || true)
        sleep 0.25
    done
}

# Minimize all game windows (used between runs so the game stays out of the way).
park_windows() {
    log_info "Parking game windows (minimized)..."
    while read -r wid; do
        [ -n "$wid" ] && python3 "$X11_HELPER" iconify "$wid" >/dev/null 2>&1 || true
    done < <(game_wids)
}

# Make sure the game window is mapped, deiconified and on the active workspace.
# EWMH activation is required: raw XMapWindow/XMapRaised do not clear the WM's
# minimized state, leaving the game throttled.
ensure_game_visible() {
    local gw active gw_desktop state
    gw="$(balatro_wid)"
    [ -z "$gw" ] && return 0

    active="$(active_desktop)"
    gw_desktop="$(window_desktop "$gw")"
    state="$(window_state "$gw")"

    # Fast path: visible already. When the session exposes no desktop info
    # (active empty), fall back to only checking the window state.
    if [ "$state" = "window state: Normal" ]; then
        if [ -z "$active" ] || [ "$gw_desktop" = "$active" ]; then
            return 0
        fi
    fi

    log_info "Un-parking game windows for the run..."
    local prev_active
    prev_active=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | grep -o '0x[0-9a-f]*' | head -n1 || true)

    while read -r wid; do
        [ -n "$wid" ] && [ -n "$active" ] && wmctrl -i -r "$wid" -t "$active" 2>/dev/null || true
    done < <(game_wids)

    wmctrl -i -a "$gw" 2>/dev/null || true
    sleep 1

    # Keep the user's focus where it was; the game runs fine unfocused.
    if [ -n "${prev_active:-}" ] && [ "$prev_active" != "$gw" ] && [ "$prev_active" != "0x0" ]; then
        wmctrl -i -a "$prev_active" 2>/dev/null || true
    fi
}

# Ask the game window to close gracefully (WM_DELETE_WINDOW). Used by
# --close-on-finish to terminate the session as soon as results are written.
request_game_close() {
    local gw
    gw="$(balatro_wid)"
    if [ -z "$gw" ]; then
        log_warn "Game window not found; cannot request close."
        return 0
    fi
    log_info "Closing the game..."
    wmctrl -i -c "$gw" 2>/dev/null || true
}

# --- Test evidence helpers ---------------------------------------------------

local_mods_for_evidence() {
    mods_default_specs | sed 's/^local://'
}

# record_launch_fingerprints MODS_DIR
#   Stores the content fingerprints of everything the session installs into the
#   session stamp, so attach runs can tell whether the working tree still
#   matches what was loaded (and therefore whether evidence may be recorded).
record_launch_fingerprints() {
    local mods_dir="$1" stamp="$mods_dir/integration_runner/session.txt" mod fp
    [ -f "$stamp" ] || return 1
    {
        for mod in $(local_mods_for_evidence); do
            if ! fp="$(evidence_mod_fingerprint "$mod")"; then
                return 1
            fi
            printf 'evhash.%s=%s\n' "$mod" "$fp"
        done
        if ! fp="$(evidence_harness_fingerprint)"; then
            return 1
        fi
        printf 'evhash.harness=%s\n' "$fp"
    } >> "$stamp"
}

# session_fingerprints_match MODS_DIR
#   True when the working tree still matches what this session was launched
#   with (all local mods + the test harness).
session_fingerprints_match() {
    local mods_dir="$1" stamp="$mods_dir/integration_runner/session.txt" mod want got
    [ -f "$stamp" ] || return 1
    for mod in $(local_mods_for_evidence); do
        want="$(awk -F= -v k="evhash.$mod" '$1 == k { print $2; exit }' "$stamp")"
        [ -n "$want" ] || return 1
        if ! got="$(evidence_mod_fingerprint "$mod")"; then
            return 1
        fi
        [ "$want" = "$got" ] || return 1
    done
    want="$(awk -F= '$1 == "evhash.harness" { print $2; exit }' "$stamp")"
    [ -n "$want" ] || return 1
    if ! got="$(evidence_harness_fingerprint)"; then
        return 1
    fi
    [ "$want" = "$got" ] || return 1
    return 0
}

# run_covers_any_suite PATTERN
#   True when the run pattern covers every test of at least one required suite.
run_covers_any_suite() {
    local pattern="$1" mod mode suite
    for mod in $(local_mods_for_evidence); do
        while IFS=$'\t' read -r mode suite; do
            [ -n "$mode" ] || continue
            if evidence_pattern_covers_suite "$mod" "$pattern" "$suite"; then
                return 0
            fi
        done < <(evidence_required_evidence "$mod" || true)
    done
    return 1
}

# --- Main flow ---
main() {
    check_prerequisites

    local mods_dir save_dir
    mods_dir="$(determine_destination)"
    if [ -z "$mods_dir" ]; then
        log_error "Could not determine the Balatro Mods folder (lib/mod_folder symlink missing?)."
        exit 1
    fi
    log_info "Mods folder: $mods_dir"
    save_dir="$(mods_save_dir "$mods_dir")"

    if [ "$DRY_RUN" = 1 ]; then
        if [ "$MODS_SET" = 0 ]; then
            local -a _defaults=()
            mapfile -t _defaults < <(mods_default_specs)
            MODS_SPECS+=("${_defaults[@]}")
        fi
        mods_plan "$mods_dir" "$save_dir" "${MODS_SPECS[@]}"
        exit $?
    fi

    if [ "$ATTACH" = 1 ]; then
        game_running || { log_error "--attach requires a running Balatro session (launch once with --keep-open)."; exit 1; }
        log_info "Attaching to the running game (no setup, no relaunch)."
        log_warn "Mod/test file changes are NOT hot-reloaded; relaunch for those."
        local stamp="$mods_dir/integration_runner/session.txt"
        if [ -f "$stamp" ]; then
            local stamp_mods stamp_pb
            stamp_mods="$(sed -n 's/^mods=//p' "$stamp" | head -n1)"
            stamp_pb="$(sed -n 's/^pb=//p' "$stamp" | head -n1)"
            log_info "Session mod set: ${stamp_mods:-<none>} (pb=${stamp_pb:-?})"
            if [[ "$PATTERN" == *"/pb"* ]] && [ "$stamp_pb" = "0" ]; then
                log_warn "Pattern '$PATTERN' looks like a PB suite, but this session was launched without --pb."
            fi
        else
            log_warn "No session stamp found; the running session was not launched by this harness."
        fi
        ensure_game_visible
    else
        game_running && { log_error "Balatro is already running. Close it, or use --attach."; exit 1; }

        if [ "$DO_SYNC" = 1 ]; then
            if [ "$MODS_SET" = 0 ]; then
                local -a _defaults=()
                mapfile -t _defaults < <(mods_default_specs)
                MODS_SPECS+=("${_defaults[@]}")
            fi
            MODS_PB_FLAG=0
            if [ "$PB_MODE" = 1 ]; then
                MODS_PB_FLAG=1
            fi
            log_info "Building a clean Mods folder (${#MODS_SPECS[@]} mod spec(s) + infra)..."
            if ! mods_setup "$mods_dir" "$save_dir" "${MODS_SPECS[@]}"; then
                log_error "Mod setup failed."
                exit 1
            fi
            if [ "$PB_MODE" = 1 ]; then
                [ -d "$mods_dir/Paperback" ] || { log_error "PB mode requested but Mods/Paperback is missing after setup."; exit 1; }
            else
                [ ! -e "$mods_dir/Paperback" ] || { log_error "Main run must stay PB-free but Mods/Paperback exists after setup."; exit 1; }
            fi
            if ! record_launch_fingerprints "$mods_dir"; then
                log_warn "Could not record launch fingerprints; this session will not produce test evidence."
            fi
        fi
    fi

    local results="$mods_dir/BalatroIntegration/results/latest.txt"
    rm -rf "$mods_dir/BalatroIntegration/results"

    # Attach exists for iteration: it keeps the game running by default. The
    # harness only quits on its own for one-shot launch runs, or when the user
    # explicitly asks for a close (as a fallback for the script-side request).
    local quit_flag=1
    if [ "$TEARDOWN" = 1 ]; then
        quit_flag=1
    elif [ "$CLOSE_ON_FINISH" = 0 ] && { [ "$ATTACH" = 1 ] || [ "$KEEP_OPEN" = 1 ]; }; then
        quit_flag=0
    fi
    # Unique per-run token: the harness echoes it into latest.txt so results
    # from a stale suite (e.g. an interrupted attach run finishing late) are
    # never mistaken for this run's.
    local run_token
    run_token="run-$(date +%s)-$$-${RANDOM}"
    printf 'pattern=%s\nquit=%s\ntoken=%s\n' "$PATTERN" "$quit_flag" "$run_token" > "$mods_dir/integration_runner/run_tests.txt"
    log_info "Test marker written (pattern='${PATTERN}', quit=${quit_flag})."

    if [ "$ATTACH" = 0 ]; then
        log_info "Launching Balatro..."
        nohup steam steam://rungameid/2379780 >/dev/null 2>&1 &
        minimize_steam_popup
    fi

    log_info "Waiting for results (timeout ${TIMEOUT}s): $results"
    local start_ts
    start_ts=$(date +%s)
    while [ ! -f "$results" ] || ! grep -qF "run_token=${run_token}" "$results"; do
        if ! game_running; then
            log_error "Game exited before writing results (no matching tests, or a crash)."
            log_error "Check the Lovely log / Mods/lovely for details."
            exit 1
        fi
        if [ $(( $(date +%s) - start_ts )) -ge "$TIMEOUT" ]; then
            log_error "Timed out after ${TIMEOUT}s waiting for results (run token ${run_token})."
            exit 1
        fi
        sleep 0.5
    done
    log_info "Suite finished in $(( $(date +%s) - start_ts ))s."

    local want_close=0
    if [ "$CLOSE_ON_FINISH" = 1 ] || [ "$TEARDOWN" = 1 ]; then
        want_close=1
    fi
    if [ "$want_close" = 1 ]; then
        request_game_close
    fi

    echo
    log_info "Results:"
    grep -v '^run_token=' "$results" | sed 's/^/  /'
    echo

    local passed failed
    passed=$(awk -F': ' '/^Passed:/{print $2; exit}' "$results")
    failed=$(awk -F': ' '/^Failed:/{print $2; exit}' "$results")

    # --- Test evidence (input for the release gate) --------------------------
    # A report is only written when the run passed, covers a full suite, and
    # the working tree still matches what this session was launched with.
    if [ "$DO_SYNC" = 1 ] && [ "${failed:-1}" = "0" ] && [ -n "${passed:-}" ] && [ "${passed:-0}" -gt 0 ]; then
        if ! run_covers_any_suite "$PATTERN"; then
            log_info "Test evidence not recorded (pattern '${PATTERN}' does not cover a full suite)."
        elif [ ! -f "$mods_dir/integration_runner/session.txt" ] || ! grep -q '^evhash\.' "$mods_dir/integration_runner/session.txt" 2>/dev/null; then
            log_info "Test evidence not recorded (no launch fingerprints for this session; use a launch run)."
        elif ! session_fingerprints_match "$mods_dir"; then
            log_warn "Test evidence not recorded: the working tree changed since this session was launched (relaunch to record evidence)."
        else
            # The session stamp records the launch mode (attach runs cannot pass
            # --pb, so the CLI flag alone would mislabel a PB session).
            local ev_mode="main" stamp_pb
            stamp_pb="$(awk -F= '$1 == "pb" { print $2; exit }' "$mods_dir/integration_runner/session.txt" 2>/dev/null || true)"
            if [ "$stamp_pb" = "1" ]; then
                ev_mode="pb"
            fi
            local ev_out=""
            if ev_out="$(evidence_write_report "$ev_mode" "$PATTERN" "$results" "$REPO_ROOT/test-reports" $(local_mods_for_evidence))"; then
                log_success "Test evidence written: ${ev_out#"$REPO_ROOT"/} (commit it before releasing)."
            else
                log_warn "Could not write test evidence (see messages above)."
            fi
        fi
    fi

    local wait_for_quit=0
    if [ "$want_close" = 1 ] || { [ "$ATTACH" = 0 ] && [ "$KEEP_OPEN" = 0 ]; }; then
        wait_for_quit=1
    fi

    if [ "$wait_for_quit" = 1 ]; then
        log_info "Waiting for the game to quit..."
        for _ in $(seq 1 60); do
            game_running || break
            sleep 1
        done
        game_running && log_warn "Game did not quit; close it manually."
    elif [ "$KEEP_VISIBLE" = 0 ]; then
        park_windows
    fi

    if [ "$TEARDOWN" = 1 ]; then
        if game_running; then
            log_error "Game still running; the pre-session state was NOT restored (backup kept)."
            exit 1
        fi
        local pending
        pending="$(mods_pending_get)"
        if [ -z "$pending" ]; then
            log_warn "No pending backup found; nothing to restore."
        else
            log_info "Restoring the pre-session state (Mods folder + configs)..."
            if mods_restore "$mods_dir" "$save_dir" "$pending"; then
                mods_pending_clear
                log_success "Pre-session state restored from $pending"
            else
                log_error "Restore failed; the backup is kept at $pending"
                exit 1
            fi
        fi
    fi

    if [ "${failed:-1}" = "0" ] && [ -n "${passed:-}" ]; then
        log_success "All tests passed (${passed} passed, 0 failed)."
        exit 0
    else
        log_error "Tests failed (${passed:-?} passed, ${failed:-?} failed)."
        exit 1
    fi
}

main "$@"
