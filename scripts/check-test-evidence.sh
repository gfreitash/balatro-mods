#!/usr/bin/env bash
# scripts/check-test-evidence.sh — release gate: verify local test evidence.
#
# A mod can only be released when test-reports/<mod>.json contains a passing
# block for every required run mode whose content fingerprint still matches the
# code being released (see scripts/lib/test-evidence.sh). Reports are written
# by scripts/run-integration-tests.sh on every fully passing run that covers a
# full suite; commit them with your changes.
#
# Usage:
#   scripts/check-test-evidence.sh [--reports-dir DIR] [--verbose] <mod-dir>...
#
# Required evidence per mod:
#   qol-bundle         main run covering riosodu/qol_bundle + PB run covering riosodu/pb
#   black-seal         main run covering riosodu/black_seal
#   rebalanced-stakes  main run covering riosodu/rebalanced_stakes
#
# Exit codes: 0 evidence OK; 1 missing/stale evidence; 2 invalid usage.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info()    { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn()    { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error()   { echo -e "${C_RED}ERROR: $1${C_NC}" >&2; }

# shellcheck source=lib/test-evidence.sh
source "$SCRIPT_DIR/lib/test-evidence.sh"

usage() {
    sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' | sed '$d'
}

mode_flags() { # MODE -> extra runner flags for that mode
    if [ "$1" = "pb" ]; then
        printf ' --pb'
    fi
    return 0
}

check_prerequisites() {
    local missing=0 tool
    for tool in git jq sha256sum; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "Required tool '$tool' is not installed."
            missing=1
        fi
    done
    if [ "$missing" = 1 ]; then
        exit 1
    fi
}

VERBOSE=0
REPORTS_DIR=""
MODS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --reports-dir) REPORTS_DIR="${2:?--reports-dir requires a value}"; shift 2 ;;
        --verbose)     VERBOSE=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        -*)            log_error "Unknown option: $1"; usage >&2; exit 2 ;;
        *)             MODS+=("${1%/}"); shift ;;
    esac
done
if [ "${#MODS[@]}" -eq 0 ]; then
    usage >&2
    exit 2
fi

check_prerequisites

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
    log_error "not inside a git repository"
    exit 1
fi
if [ -z "$REPORTS_DIR" ]; then
    REPORTS_DIR="$REPO_ROOT/test-reports"
fi
if [ ! -d "$REPORTS_DIR" ]; then
    log_error "no test reports found at $REPORTS_DIR"
    log_error "run the suite locally (scripts/run-integration-tests.sh) and commit test-reports/<mod>.json"
    exit 1
fi

rel() { # PATH -> path relative to the repo root when possible
    printf '%s' "${1#"$REPO_ROOT"/}"
}

# report_matches REPORT MOD MODE EXPECTED MOD_FP HARNESS_FP -> 0 when valid
report_matches() {
    local report="$1" mod="$2" mode="$3" expected="$4" mod_fp="$5" harness_fp="$6"
    [ "$(jq -r '.schema // empty' "$report" 2>/dev/null || true)" = "balatro-test-evidence/2" ] || return 1
    [ "$(jq -r '.mod // empty' "$report" 2>/dev/null || true)" = "$mod" ] || return 1
    [ "$(jq -r --arg mode "$mode" '.runs[$mode].mode // empty' "$report" 2>/dev/null || true)" = "$mode" ] || return 1
    [ "$(jq -r --arg mode "$mode" --arg k "$mod" '.runs[$mode].hashes.mods[$k] // empty' "$report" 2>/dev/null || true)" = "$mod_fp" ] || return 1
    [ "$(jq -r --arg mode "$mode" '.runs[$mode].hashes.harness // empty' "$report" 2>/dev/null || true)" = "$harness_fp" ] || return 1
    [ "$(jq -r --arg mode "$mode" '.runs[$mode].totals.failed // 1' "$report" 2>/dev/null || true)" = "0" ] || return 1
    local missing
    missing="$(comm -23 \
        <(printf '%s\n' "$expected" | LC_ALL=C sort -u) \
        <(jq -r --arg mode "$mode" '.runs[$mode].tests[]? | select(.passed) | .name' "$report" 2>/dev/null | LC_ALL=C sort -u || true) \
        || true)"
    [ -z "$missing" ]
}

# diagnose_report REPORT MOD MODE EXPECTED MOD_FP HARNESS_FP -> first reason
diagnose_report() {
    local report="$1" mod="$2" mode="$3" expected="$4" mod_fp="$5" harness_fp="$6"
    local schema rmod rmode rmodhash rharness rfailed missing
    schema="$(jq -r '.schema // empty' "$report" 2>/dev/null || true)"
    rmod="$(jq -r '.mod // empty' "$report" 2>/dev/null || true)"
    rmode="$(jq -r --arg mode "$mode" '.runs[$mode].mode // empty' "$report" 2>/dev/null || true)"
    rmodhash="$(jq -r --arg mode "$mode" --arg k "$mod" '.runs[$mode].hashes.mods[$k] // empty' "$report" 2>/dev/null || true)"
    rharness="$(jq -r --arg mode "$mode" '.runs[$mode].hashes.harness // empty' "$report" 2>/dev/null || true)"
    rfailed="$(jq -r --arg mode "$mode" '.runs[$mode].totals.failed // empty' "$report" 2>/dev/null || true)"

    if [ "$schema" != "balatro-test-evidence/2" ]; then
        printf 'unknown or legacy schema'
        return 0
    fi
    if [ "$rmod" != "$mod" ]; then
        printf "report is for mod '%s'" "$rmod"
        return 0
    fi
    if [ -z "$rmode" ]; then
        printf "no '%s' run recorded" "$mode"
        return 0
    fi
    if [ "$rmodhash" != "$mod_fp" ]; then
        printf 'mod content changed since this run was recorded'
        return 0
    fi
    if [ "$rharness" != "$harness_fp" ]; then
        printf 'test harness changed since this run was recorded'
        return 0
    fi
    if [ "$rfailed" != "0" ]; then
        printf 'recorded %s failing test(s)' "$rfailed"
        return 0
    fi
    missing="$(comm -23 \
        <(printf '%s\n' "$expected" | LC_ALL=C sort -u) \
        <(jq -r --arg mode "$mode" '.runs[$mode].tests[]? | select(.passed) | .name' "$report" 2>/dev/null | LC_ALL=C sort -u || true) \
        || true)"
    if [ -n "$missing" ]; then
        printf '%s expected test(s) not recorded as passed' "$(printf '%s\n' "$missing" | wc -l | tr -d ' ')"
        return 0
    fi
    printf 'unknown mismatch'
}

check_mod() {
    local mod="$1"
    local required
    if ! required="$(evidence_required_evidence "$mod")"; then
        log_error "$mod: no evidence requirements defined (add it to scripts/lib/test-evidence.sh)"
        return 1
    fi

    local mod_fp harness_fp report
    if ! mod_fp="$(evidence_mod_fingerprint "$mod")"; then
        log_error "$mod: could not fingerprint the mod content"
        return 1
    fi
    if ! harness_fp="$(evidence_harness_fingerprint)"; then
        log_error "$mod: could not fingerprint the test harness"
        return 1
    fi
    report="$(evidence_report_file "$REPORTS_DIR" "$mod")"

    local ok=0 mode suite expected generated pattern
    while IFS=$'\t' read -r mode suite; do
        [ -n "$mode" ] || continue
        expected="$(evidence_expected_tests "$mod" "$suite")"
        if [ -z "$expected" ]; then
            log_error "$mod: no tests found for suite '$suite' in the test sources"
            ok=1
            continue
        fi

        if [ ! -f "$report" ]; then
            ok=1
            log_error "$mod: missing $mode evidence (no $(rel "$report"))"
            log_error "  fix: run ./scripts/run-integration-tests.sh$(mode_flags "$mode") and commit test-reports/$mod.json"
            continue
        fi

        if report_matches "$report" "$mod" "$mode" "$expected" "$mod_fp" "$harness_fp"; then
            log_success "$mod: $mode evidence OK ($(rel "$report"))"
            if [ "$VERBOSE" = 1 ]; then
                generated="$(jq -r --arg mode "$mode" '.runs[$mode].generated_at // "unknown"' "$report" 2>/dev/null || printf 'unknown')"
                pattern="$(jq -r --arg mode "$mode" '.runs[$mode].pattern // ""' "$report" 2>/dev/null || true)"
                log_info "  recorded $generated (pattern '${pattern}')"
            fi
        else
            ok=1
            log_error "$mod: missing or stale $mode evidence in $(rel "$report")"
            log_error "  $(diagnose_report "$report" "$mod" "$mode" "$expected" "$mod_fp" "$harness_fp")"
            log_error "  fix: run ./scripts/run-integration-tests.sh$(mode_flags "$mode") and commit test-reports/$mod.json"
        fi
    done <<<"$required"
    return "$ok"
}

failures=0
for mod in "${MODS[@]}"; do
    if ! check_mod "$mod"; then
        failures=$((failures + 1))
    fi
done

echo
if [ "$failures" -gt 0 ]; then
    log_error "$failures mod(s) lack valid test evidence — release is blocked."
    exit 1
fi
log_success "Test evidence OK for: ${MODS[*]}"
