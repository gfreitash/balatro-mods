#!/usr/bin/env bash
# scripts/check-test-evidence.sh — release gate: verify local test evidence.
#
# A mod can only be released when the repository contains a passing
# test-evidence report whose content fingerprint still matches the code being
# released (see scripts/lib/test-evidence.sh). Reports are written by
# scripts/run-integration-tests.sh on every fully passing run that covers a
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
    log_error "run the suite locally (scripts/run-integration-tests.sh) and commit test-reports/"
    exit 1
fi

rel() { # PATH -> path relative to the repo root when possible
    printf '%s' "${1#"$REPO_ROOT"/}"
}

# list_reports_newest_first -> report paths, newest generated_at first
list_reports_newest_first() {
    local file
    for file in "$REPORTS_DIR"/*.json; do
        [ -f "$file" ] || continue
        printf '%s\t%s\n' \
            "$(jq -r '.generated_at // "1970-01-01T00:00:00Z"' "$file" 2>/dev/null || printf '1970-01-01T00:00:00Z')" \
            "$file"
    done | LC_ALL=C sort -r | cut -f2-
}

# report_matches REPORT MOD MODE EXPECTED MOD_FP HARNESS_FP -> 0 when valid
report_matches() {
    local report="$1" mod="$2" mode="$3" expected="$4" mod_fp="$5" harness_fp="$6"
    [ "$(jq -r '.schema // empty' "$report" 2>/dev/null || true)" = "balatro-test-evidence/1" ] || return 1
    [ "$(jq -r '.mode // empty' "$report" 2>/dev/null || true)" = "$mode" ] || return 1
    [ "$(jq -r --arg k "$mod" '.hashes.mods[$k] // empty' "$report" 2>/dev/null || true)" = "$mod_fp" ] || return 1
    [ "$(jq -r '.hashes.harness // empty' "$report" 2>/dev/null || true)" = "$harness_fp" ] || return 1
    [ "$(jq -r '.totals.failed // 1' "$report" 2>/dev/null || true)" = "0" ] || return 1
    local missing
    missing="$(comm -23 \
        <(printf '%s\n' "$expected" | LC_ALL=C sort -u) \
        <(jq -r '.tests[] | select(.passed) | .name' "$report" 2>/dev/null | LC_ALL=C sort -u || true) \
        || true)"
    [ -z "$missing" ]
}

# diagnose_report REPORT MOD MODE EXPECTED MOD_FP HARNESS_FP -> first reason
diagnose_report() {
    local report="$1" mod="$2" mode="$3" expected="$4" mod_fp="$5" harness_fp="$6"
    local schema rmode rmod rharness rfailed missing
    schema="$(jq -r '.schema // empty' "$report" 2>/dev/null || true)"
    rmode="$(jq -r '.mode // empty' "$report" 2>/dev/null || true)"
    rmod="$(jq -r --arg k "$mod" '.hashes.mods[$k] // empty' "$report" 2>/dev/null || true)"
    rharness="$(jq -r '.hashes.harness // empty' "$report" 2>/dev/null || true)"
    rfailed="$(jq -r '.totals.failed // empty' "$report" 2>/dev/null || true)"

    if [ "$schema" != "balatro-test-evidence/1" ]; then
        printf 'unknown schema'
        return 0
    fi
    if [ "$rmode" != "$mode" ]; then
        printf "mode is '%s'" "$rmode"
        return 0
    fi
    if [ "$rmod" != "$mod_fp" ]; then
        printf 'mod content changed since this report was recorded'
        return 0
    fi
    if [ "$rharness" != "$harness_fp" ]; then
        printf 'test harness changed since this report was recorded'
        return 0
    fi
    if [ "$rfailed" != "0" ]; then
        printf 'recorded %s failing test(s)' "$rfailed"
        return 0
    fi
    missing="$(comm -23 \
        <(printf '%s\n' "$expected" | LC_ALL=C sort -u) \
        <(jq -r '.tests[] | select(.passed) | .name' "$report" 2>/dev/null | LC_ALL=C sort -u || true) \
        || true)"
    if [ -n "$missing" ]; then
        printf '%s expected test(s) not recorded as passed' "$(printf '%s\n' "$missing" | wc -l | tr -d ' ')"
        return 0
    fi
    printf 'unknown mismatch'
}

# find_newest_report_of_mode MODE -> newest report path with that mode
find_newest_report_of_mode() {
    local mode="$1" report
    while IFS= read -r report; do
        [ -n "$report" ] || continue
        if [ "$(jq -r '.mode // empty' "$report" 2>/dev/null || true)" = "$mode" ]; then
            printf '%s' "$report"
            return 0
        fi
    done < <(list_reports_newest_first)
    return 1
}

check_mod() {
    local mod="$1"
    local required
    if ! required="$(evidence_required_evidence "$mod")"; then
        log_error "$mod: no evidence requirements defined (add it to scripts/lib/test-evidence.sh)"
        return 1
    fi

    local mod_fp harness_fp
    if ! mod_fp="$(evidence_mod_fingerprint "$mod")"; then
        log_error "$mod: could not fingerprint the mod content"
        return 1
    fi
    if ! harness_fp="$(evidence_harness_fingerprint)"; then
        log_error "$mod: could not fingerprint the test harness"
        return 1
    fi

    local ok=0 mode suite expected match report
    while IFS=$'\t' read -r mode suite; do
        [ -n "$mode" ] || continue
        expected="$(evidence_expected_tests "$mod" "$suite")"
        if [ -z "$expected" ]; then
            log_error "$mod: no tests found for suite '$suite' in the test sources"
            ok=1
            continue
        fi

        match=""
        while IFS= read -r report; do
            [ -n "$report" ] || continue
            if [ "$VERBOSE" = 1 ]; then
                log_info "  considering $(rel "$report")"
            fi
            if report_matches "$report" "$mod" "$mode" "$expected" "$mod_fp" "$harness_fp"; then
                match="$report"
                break
            fi
        done < <(list_reports_newest_first)

        if [ -n "$match" ]; then
            log_success "$mod: $mode evidence OK ($(rel "$match"))"
        else
            ok=1
            log_error "$mod: missing or stale $mode evidence for '$suite'"
            local diag_report
            diag_report="$(find_newest_report_of_mode "$mode" || true)"
            if [ -n "$diag_report" ]; then
                log_error "  newest $mode report ($(rel "$diag_report")): $(diagnose_report "$diag_report" "$mod" "$mode" "$expected" "$mod_fp" "$harness_fp")"
            else
                log_error "  no $mode report found in $REPORTS_DIR"
            fi
            log_error "  fix: run ./scripts/run-integration-tests.sh$(mode_flags "$mode") and commit the new test-reports/*.json"
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
