#!/usr/bin/env bash
# scripts/test-mods.sh — manage the Balatro Mods folder for integration test runs.
#
# The test runner (scripts/run-integration-tests.sh) builds a clean Mods folder
# for every launch: it backs up what it will wipe (Mods entries + the save
# dir's config/), wipes everything managed, and installs exactly the declared
# mods plus the harness infrastructure. This script exposes the same machinery
# for manual use and recovery.
#
# Commands:
#   plan        Print what a setup would do (no writes; network reads only)
#   setup       Back up + clean + install the declared mod set
#   teardown    Restore the pending backup exactly (Mods entries + config/)
#   clean       Wipe all managed entries (no restore; the backup is kept)
#   status      Show the pending backup and the last session stamp
#   prune       Keep only the newest snapshots (default 3, plus the pending one)
#
# Options:
#   --mods SPEC[,SPEC...]  Content mods to install (repeatable).
#                          Default: all local repo mods; 'none' = infra only.
#                          Specs: local:<dir> | thunderstore:<ns>-<name>[@<ver>] |
#                                 github:<owner>/<repo>[@<ref>][::<subdir>] |
#                                 github-release:<owner>/<repo>@<tag>#<asset>
#   --dest DIR             Mods folder to operate on (default: lib/mod_folder)
#   --save-dir DIR         Balatro save dir (default: the parent of --dest)
#   --refresh              Re-resolve / re-download instead of using the cache
#   --offline              Resolve from the cache only (no network)
#   -h, --help             Show this help
#
# With --dest the game-closed check is skipped and the basename guard relaxed,
# so scratch folders (e.g. /tmp/opencode/fake-mods) can be exercised safely.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info()    { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn()    { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error()   { echo -e "${C_RED}ERROR: $1${C_NC}" >&2; }

# shellcheck source=lib/mods.sh
source "$SCRIPT_DIR/lib/mods.sh"

usage() {
    sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' | sed '$d'
}

check_prerequisites() {
    local missing=0 tool
    for tool in rsync curl unzip jq; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "Required tool '$tool' is not installed."
            missing=1
        fi
    done
    if [ "$missing" = 1 ]; then
        exit 1
    fi
}

game_running() {
    pgrep -f 'Balatro\.exe' >/dev/null 2>&1
}

require_game_closed() {
    if [ "$SCRATCH" = 1 ]; then
        return 0
    fi
    if game_running; then
        log_error "Balatro is running. Close it first, then re-run."
        log_error "  W=\$(wmctrl -lx | grep -i steam_app_2379780 | grep -v Lovely | head -n1 | awk '{print \$1}'); wmctrl -i -c \"\$W\""
        return 1
    fi
    return 0
}

COMMAND=""
DEST=""
SAVE_DIR=""
declare -a SPECS=()
MODS_SET=0
MODS_REFRESH=0
MODS_OFFLINE=0

while [ $# -gt 0 ]; do
    case "$1" in
        plan|setup|teardown|clean|status|prune)
            [ -z "$COMMAND" ] || { log_error "Only one command is allowed."; exit 2; }
            COMMAND="$1"; shift ;;
        --mods)
            IFS=',' read -r -a _split <<< "${2:?--mods requires a value}"
            SPECS+=("${_split[@]}")
            MODS_SET=1
            shift 2 ;;
        --dest)     DEST="${2:?--dest requires a value}"; shift 2 ;;
        --save-dir) SAVE_DIR="${2:?--save-dir requires a value}"; shift 2 ;;
        --refresh)  MODS_REFRESH=1; shift ;;
        --offline)  MODS_OFFLINE=1; shift ;;
        -h|--help)  usage; exit 0 ;;
        *)          log_error "Unknown argument: $1"; usage >&2; exit 2 ;;
    esac
done

if [ -z "$COMMAND" ]; then
    usage >&2
    exit 2
fi

check_prerequisites

SCRATCH=0
if [ -n "$DEST" ]; then
    SCRATCH=1
    MODS_ALLOW_NONSTD_DEST=1
else
    DEST="$(mods_determine_destination)"
    if [ -z "$DEST" ]; then
        log_error "Could not determine the Balatro Mods folder (lib/mod_folder symlink missing?)."
        log_error "Use --dest to target a folder explicitly."
        exit 1
    fi
fi
if [ -z "$SAVE_DIR" ]; then
    SAVE_DIR="$(mods_save_dir "$DEST")"
fi

if [ "$MODS_SET" = 0 ]; then
    mapfile -t SPECS < <(mods_default_specs)
elif [ "${#SPECS[@]}" = 1 ] && [ "${SPECS[0]}" = "none" ]; then
    SPECS=()
fi

case "$COMMAND" in
    plan)
        mods_plan "$DEST" "$SAVE_DIR" "${SPECS[@]}" || exit 1
        ;;
    setup)
        require_game_closed
        mods_setup "$DEST" "$SAVE_DIR" "${SPECS[@]}" || { log_error "Setup failed."; exit 1; }
        if [ "${MODS_PENDING_REUSED:-0}" = 1 ]; then
            log_success "Mods folder ready (reused backup $MODS_BACKUP_DIR)."
        else
            log_success "Mods folder ready (backup $MODS_BACKUP_DIR)."
        fi
        ;;
    teardown)
        require_game_closed
        pending="$(mods_pending_get)"
        if [ -z "$pending" ]; then
            log_warn "No pending backup to restore."
            exit 0
        fi
        if ! mods_restore "$DEST" "$SAVE_DIR" "$pending"; then
            log_error "Restore failed; the backup is kept at $pending"
            exit 1
        fi
        mods_pending_clear
        log_success "Pre-session state restored from $pending"
        ;;
    clean)
        require_game_closed
        mods_clean "$DEST" || exit 1
        log_success "Managed entries removed (lovely/ preserved)."
        if [ -n "$(mods_pending_get)" ]; then
            log_warn "A pending backup still exists; 'teardown' can restore it."
        fi
        ;;
    status)
        echo "mods dir:       $DEST"
        echo "save dir:       $SAVE_DIR"
        pending="$(mods_pending_get)"
        echo "pending backup: ${pending:-<none>}"
        stamp="$DEST/integration_runner/session.txt"
        if [ -f "$stamp" ]; then
            echo "session stamp:"
            sed 's/^/  /' "$stamp"
        else
            echo "session stamp:  <none>"
        fi
        ;;
    prune)
        mods_prune_snapshots
        log_success "Snapshots pruned (keeping newest $MODS_SNAPSHOTS_KEEP plus the pending one)."
        ;;
esac
