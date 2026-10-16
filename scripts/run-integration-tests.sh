#!/usr/bin/env bash
#
# Runs BalatroIntegration test suites inside a real Balatro session.
#
# Modes:
#   launch (default)   Syncs the mods, installs the BalatroIntegration fork and
#                      the local harness mod, launches Balatro via Steam, waits
#                      for the suite results and reports them. Paperback is
#                      REMOVED from the Mods folder so the main run stays
#                      PB-free (the non-PB branches keep being tested).
#   --pb               PB mode: installs the test-only Paperback library
#                      (lib/paperback) and, unless a pattern is given, runs the
#                      reduced PB scope (default pattern "riosodu/pb"). Keep PB
#                      and non-PB runs separate: PB must not affect unrelated
#                      tests, and both compat branches stay exercised.
#   --attach           The game is already running (launched once with
#                      --keep-open): skips sync/launch and re-runs the selected
#                      tests in the live session via the harness marker.
#                      Iterations take seconds instead of a full boot, and the
#                      game is kept running for the next iteration; pass
#                      --close-on-finish to close it when done.
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
#   --attach           Re-run tests in an already-running game (fast iteration).
#   --close-on-finish  Close the game as soon as the suite results are written.
#   --timeout SECS     Max seconds to wait for results (default: 900).
#   --keep-open        Leave the game running after the suite finishes
#                      (implicit in --attach).
#   --keep-visible     Don't minimize (park) the game windows after the run.
#   --no-sync          Skip syncing mods/Integration/harness/Paperback to Mods.
#   --pb               Launch in PB mode (installs lib/paperback and switches
#                      the default pattern to riosodu/pb). Launch mode only;
#                      rejected when combined with --attach.
#   -h, --help         Show this help.
#
# Exit codes:
#   0 all tests passed; 1 failures/timeout/errors; 2 invalid usage.
#
# Note: --attach does not hot-reload mod/test code; file changes need a fresh
# launch.

set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info()    { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn()    { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error()   { echo -e "${C_RED}ERROR: $1${C_NC}" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INTEGRATION_SRC="$REPO_ROOT/lib/BalatroIntegration"
HARNESS_SRC="$REPO_ROOT/tools/integration-runner"
PAPERBACK_SRC="$REPO_ROOT/lib/paperback"
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
        -h|--help)      sed -n '3,51p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*)             log_error "Unknown option: $1"; exit 2 ;;
        *)              PATTERN="$1"; PATTERN_SET=1; shift ;;
    esac
done

if [ "$PB_MODE" = 1 ] && [ "$ATTACH" = 1 ]; then
    log_warn "--pb only applies to launch mode; --attach uses the running session's load state."
    exit 2
fi

if [ "$PB_MODE" = 1 ] && [ "$PATTERN_SET" = 0 ]; then
    PATTERN="riosodu/pb"
fi

# --- Prerequisite checks ---
check_prerequisites() {
    local missing=0
    local tools=(rsync python3 wmctrl xprop)
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
    log_info "Closing the game (--close-on-finish)..."
    wmctrl -i -c "$gw" 2>/dev/null || true
}

# --- Main flow ---
main() {
    check_prerequisites

    local mods_dir
    mods_dir="$(determine_destination)"
    if [ -z "$mods_dir" ]; then
        log_error "Could not determine the Balatro Mods folder (lib/mod_folder symlink missing?)."
        exit 1
    fi
    log_info "Mods folder: $mods_dir"

    if [ "$ATTACH" = 1 ]; then
        game_running || { log_error "--attach requires a running Balatro session (launch once with --keep-open)."; exit 1; }
        log_info "Attaching to the running game (no sync, no relaunch)."
        log_warn "Mod/test file changes are NOT hot-reloaded; relaunch for those."
        ensure_game_visible
    else
        game_running && { log_error "Balatro is already running. Close it, or use --attach."; exit 1; }

        if [ "$DO_SYNC" = 1 ]; then
            log_info "Syncing mods via sync-mods.sh..."
            (cd "$REPO_ROOT" && ./sync-mods.sh)

            log_info "Installing BalatroIntegration and harness mod..."
            rsync -a --delete --exclude='.git' --exclude='results' "$INTEGRATION_SRC/" "$mods_dir/BalatroIntegration/"
            rsync -a --delete "$HARNESS_SRC/" "$mods_dir/integration_runner/"

            if [ "$PB_MODE" = 1 ]; then
                if [ -d "$PAPERBACK_SRC" ]; then
                    log_info "Installing test-only Paperback (PB mode)..."
                    rsync -a --delete "$PAPERBACK_SRC/" "$mods_dir/Paperback/"
                else
                    log_error "PB mode requested but $PAPERBACK_SRC is missing. Run ./setup-libs.sh first."
                    exit 1
                fi
            elif [ -d "$mods_dir/Paperback" ]; then
                log_info "Removing test-only Paperback (main run stays PB-free)..."
                rm -rf "$mods_dir/Paperback"
            fi
        fi
    fi

    local results="$mods_dir/BalatroIntegration/results/latest.txt"
    rm -rf "$mods_dir/BalatroIntegration/results"

    # Attach exists for iteration: it keeps the game running by default. The
    # harness only quits on its own for one-shot launch runs, or when the user
    # explicitly asks for a close (as a fallback for the script-side request).
    local quit_flag=1
    if [ "$CLOSE_ON_FINISH" = 0 ] && { [ "$ATTACH" = 1 ] || [ "$KEEP_OPEN" = 1 ]; }; then
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

    if [ "$CLOSE_ON_FINISH" = 1 ]; then
        request_game_close
    fi

    echo
    log_info "Results:"
    grep -v '^run_token=' "$results" | sed 's/^/  /'
    echo

    local passed failed
    passed=$(awk -F': ' '/^Passed:/{print $2; exit}' "$results")
    failed=$(awk -F': ' '/^Failed:/{print $2; exit}' "$results")

    local wait_for_quit=0
    if [ "$CLOSE_ON_FINISH" = 1 ] || { [ "$ATTACH" = 0 ] && [ "$KEEP_OPEN" = 0 ]; }; then
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

    if [ "${failed:-1}" = "0" ] && [ -n "${passed:-}" ]; then
        log_success "All tests passed (${passed} passed, 0 failed)."
        exit 0
    else
        log_error "Tests failed (${passed:-?} passed, ${failed:-?} failed)."
        exit 1
    fi
}

main "$@"
