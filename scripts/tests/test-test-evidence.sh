#!/usr/bin/env bash
# scripts/tests/test-test-evidence.sh
#
# Fixture-based tests for the test-evidence fingerprints and the release gate
# (scripts/lib/test-evidence.sh + scripts/check-test-evidence.sh). No network,
# no game: builds a throwaway git repo and exercises the machinery against it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../lib/test-evidence.sh
source "$REPO_ROOT/scripts/lib/test-evidence.sh"

CHECKER="$REPO_ROOT/scripts/check-test-evidence.sh"

total=0
failed=0

check() { # DESC ACTUAL EXPECTED
    total=$((total + 1))
    if [ "$2" != "$3" ]; then
        failed=$((failed + 1))
        echo "FAIL: $1: expected '$3', got '$2'"
    fi
}

check_ne() { # DESC ACTUAL UNEXPECTED
    total=$((total + 1))
    if [ "$2" = "$3" ]; then
        failed=$((failed + 1))
        echo "FAIL: $1: expected different values, got '$2'"
    fi
}

check_exit() { # DESC EXPECTED_RC COMMAND...
    total=$((total + 1))
    local desc="$1" want="$2"
    shift 2
    local rc=0 out=""
    out="$("$@" 2>&1)" || rc=$?
    if [ "$rc" != "$want" ]; then
        failed=$((failed + 1))
        echo "FAIL: $desc: expected exit $want, got $rc"
        printf '%s\n' "$out" | sed 's/^/    | /'
    fi
}

# --- fixture -----------------------------------------------------------------
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/test-evidence-fixture.XXXXXX")"
trap 'cd /; rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE"/{qol-bundle/src,qol-bundle/tests,black-seal/tests,_common,tools/integration-runner,test-reports}
cd "$FIXTURE"
git init -q
git config user.email "test@example.com"
git config user.name "Test"

printf '{"name":"QoL_Bundle","version":"1.0.0"}\n' > qol-bundle/smods.json
printf '{"name":"QoL_Bundle","version_number":"1.0.0"}\n' > qol-bundle/manifest.json
printf '# Changelog\n' > qol-bundle/CHANGELOG.md
printf 'return {}\n' > qol-bundle/src/init.lua
printf 'BInt.register_test("riosodu/qol_bundle/alpha", function(test) end)\n' > qol-bundle/tests.lua
printf 'BInt.register_test("riosodu/qol_bundle/beta", function(test) end)\n' > qol-bundle/tests/a.lua
printf 'BInt.register_test("riosodu/qol_bundle/beta2", function(test) end)\n' > qol-bundle/tests/b.lua
printf 'BInt.register_test("riosodu/pb/compat_alpha", function(test) end)\n' > qol-bundle/tests/pb_compat.lua
printf '{"name":"Black_Seal","version":"1.0.0"}\n' > black-seal/smods.json
printf 'BInt.register_test("riosodu/black_seal/x", function(test) end)\n' > black-seal/tests.lua
printf 'return "1.0.0"\n' > _common/version.lua
printf 'return {}\n' > _common/lib.lua
printf -- '-- harness\n' > tools/integration-runner/main.lua
git add -A
git commit -qm init

# --- fingerprints ------------------------------------------------------------
BASE="$(evidence_mod_fingerprint qol-bundle)"
check "fingerprint is stable" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

# Version metadata and documentation must NOT invalidate evidence (release
# bumps and docs touch these).
printf '{"name":"QoL_Bundle","version":"9.9.9"}\n' > qol-bundle/smods.json
check "smods.json version bump ignored" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf '{"name":"QoL_Bundle","version_number":"9.9.9"}\n' > qol-bundle/manifest.json
check "manifest.json version bump ignored" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf '# Changelog v9\n' > qol-bundle/CHANGELOG.md
check "CHANGELOG edit ignored" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf '# README v9\n' > qol-bundle/README.md
check "README edit ignored" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf 'return "9.9.9"\n' > _common/version.lua
check "_common/version.lua bump ignored" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

# Source / test / shared-lib changes must invalidate.
printf 'return { changed = true }\n' > qol-bundle/src/init.lua
check_ne "source change invalidates" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf 'return {}\n' > qol-bundle/src/init.lua
check "source restore matches again" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

printf 'BInt.register_test("riosodu/qol_bundle/gamma", function(test) end)\n' >> qol-bundle/tests/b.lua
check_ne "test change invalidates" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf 'BInt.register_test("riosodu/qol_bundle/beta2", function(test) end)\n' > qol-bundle/tests/b.lua
check "test restore matches again" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

printf 'return { y = 1 }\n' > _common/lib.lua
check_ne "_common change invalidates" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
printf 'return {}\n' > _common/lib.lua
check "common restore matches again" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

printf 'return {}\n' > qol-bundle/src/new.lua
check_ne "untracked file invalidates" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
rm qol-bundle/src/new.lua
check "untracked removal matches again" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

mv qol-bundle/src/init.lua qol-bundle/src/init.lua.bak
check_ne "deletion invalidates" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"
mv qol-bundle/src/init.lua.bak qol-bundle/src/init.lua
check "deletion restore matches again" "$(evidence_mod_fingerprint qol-bundle)" "$BASE"

HARNESS_BASE="$(evidence_harness_fingerprint)"
printf -- '-- harness v2\n' > tools/integration-runner/main.lua
check_ne "harness change invalidates" "$(evidence_harness_fingerprint)" "$HARNESS_BASE"
printf -- '-- harness\n' > tools/integration-runner/main.lua
check "harness restore matches again" "$(evidence_harness_fingerprint)" "$HARNESS_BASE"

# --- expected tests / pattern coverage / run targets -------------------------
check "expected main tests" \
    "$(evidence_expected_tests qol-bundle riosodu/qol_bundle | paste -sd, -)" \
    "riosodu/qol_bundle/alpha,riosodu/qol_bundle/beta,riosodu/qol_bundle/beta2"
check "expected pb tests" \
    "$(evidence_expected_tests qol-bundle riosodu/pb | paste -sd, -)" \
    "riosodu/pb/compat_alpha"
check "expected unknown suite" "$(evidence_expected_tests qol-bundle riosodu/nope)" ""
check "expected tests for a whole mode" \
    "$(evidence_mode_expected_tests qol-bundle main | paste -sd, -)" \
    "riosodu/qol_bundle/alpha,riosodu/qol_bundle/beta,riosodu/qol_bundle/beta2"

check_exit "pattern covers exact suite"  0 evidence_pattern_covers_suite qol-bundle riosodu/qol_bundle riosodu/qol_bundle
check_exit "pattern covers all suites"   0 evidence_pattern_covers_suite qol-bundle riosodu riosodu/qol_bundle
check_exit "pattern covers prefix"       0 evidence_pattern_covers_suite qol-bundle riosodu/qol riosodu/qol_bundle
check_exit "empty pattern covers"        0 evidence_pattern_covers_suite qol-bundle "" riosodu/qol_bundle
check_exit "narrow pattern does not"     1 evidence_pattern_covers_suite qol-bundle riosodu/qol_bundle/alpha riosodu/qol_bundle
check_exit "other suite pattern does not" 1 evidence_pattern_covers_suite qol-bundle riosodu/pb riosodu/qol_bundle

# --- release gate ------------------------------------------------------------
check_exit "gate fails with no reports" 1 "$CHECKER" qol-bundle

printf 'Integration Test Results\n========================\n\nTotal: 3\nPassed: 3\nFailed: 0\nDuration: 1.0s\n\n' > results-main.txt
printf 'test=riosodu/qol_bundle/alpha\tpass\n' >> results-main.txt
printf 'test=riosodu/qol_bundle/beta\tpass\n' >> results-main.txt
printf 'test=riosodu/qol_bundle/beta2\tpass\n' >> results-main.txt
MAIN_REPORT="$(evidence_write_report main riosodu/qol_bundle results-main.txt test-reports qol-bundle)"
check "main report name" "$(basename "$MAIN_REPORT")" "qol-bundle.json"
check "report schema" "$(jq -r '.schema' "$MAIN_REPORT")" "balatro-test-evidence/2"
check "report mod" "$(jq -r '.mod' "$MAIN_REPORT")" "qol-bundle"
check "main block mode" "$(jq -r '.runs.main.mode' "$MAIN_REPORT")" "main"
check "main block totals" "$(jq -c '.runs.main.totals' "$MAIN_REPORT")" '{"total":3,"passed":3,"failed":0}'
check "main block has only its own mod hash" "$(jq -r '.runs.main.hashes.mods | keys | join(",")' "$MAIN_REPORT")" "qol-bundle"
check "main block filtered to the qol suite" "$(jq -r '.runs.main.tests[].name' "$MAIN_REPORT" | paste -sd, -)" "riosodu/qol_bundle/alpha,riosodu/qol_bundle/beta,riosodu/qol_bundle/beta2"
check "main write leaves pb absent" "$(jq -r '.runs.pb // "absent"' "$MAIN_REPORT")" "absent"

check "covered mods for the qol suite" "$(evidence_covered_mods main riosodu/qol_bundle qol-bundle black-seal | paste -sd, -)" "qol-bundle"
check "covered mods for the full main pattern" "$(evidence_covered_mods main riosodu qol-bundle black-seal | paste -sd, -)" "qol-bundle,black-seal"
check "covered mods for a narrow pattern" "$(evidence_covered_mods main riosodu/qol_bundle/alpha qol-bundle | paste -sd, -)" ""

# qol-bundle also requires PB evidence.
check_exit "gate requires pb evidence for qol-bundle" 1 "$CHECKER" qol-bundle

printf 'Integration Test Results\n========================\n\nTotal: 1\nPassed: 1\nFailed: 0\nDuration: 0.5s\n\n' > results-pb.txt
printf 'test=riosodu/pb/compat_alpha\tpass\n' >> results-pb.txt
PB_REPORT="$(evidence_write_report pb riosodu/pb results-pb.txt test-reports qol-bundle)"
check "pb write reuses the mod file" "$PB_REPORT" "$MAIN_REPORT"
check "pb block totals" "$(jq -c '.runs.pb.totals' "$MAIN_REPORT")" '{"total":1,"passed":1,"failed":0}'
check "pb write preserves main" "$(jq -c '.runs.main.totals' "$MAIN_REPORT")" '{"total":3,"passed":3,"failed":0}'
check_exit "gate passes with main+pb evidence" 0 "$CHECKER" qol-bundle

# Content change invalidates until the suite is re-run.
printf 'return { changed = true }\n' > qol-bundle/src/init.lua
check_exit "gate fails after source change" 1 "$CHECKER" qol-bundle
printf 'return {}\n' > qol-bundle/src/init.lua
check_exit "gate passes after restore" 0 "$CHECKER" qol-bundle

# Harness change invalidates.
printf -- '-- harness v3\n' > tools/integration-runner/main.lua
check_exit "gate fails after harness change" 1 "$CHECKER" qol-bundle
printf -- '-- harness\n' > tools/integration-runner/main.lua
check_exit "gate passes after harness restore" 0 "$CHECKER" qol-bundle

# black-seal needs only a main report.
check_exit "gate fails for black-seal without evidence" 1 "$CHECKER" black-seal
printf 'Integration Test Results\n========================\n\nTotal: 1\nPassed: 1\nFailed: 0\nDuration: 0.5s\n\n' > results-bs.txt
printf 'test=riosodu/black_seal/x\tpass\n' >> results-bs.txt
BS_REPORT="$(evidence_write_report main riosodu/black_seal results-bs.txt test-reports black-seal)"
check "black-seal report name" "$(basename "$BS_REPORT")" "black-seal.json"
check_exit "gate passes for black-seal" 0 "$CHECKER" black-seal

# A failing or partial run must not replace valid evidence.
BEFORE="$(jq -c . "$MAIN_REPORT")"
mkdir -p reports-fail
printf 'Integration Test Results\n========================\n\nTotal: 1\nPassed: 0\nFailed: 1\nDuration: 0.5s\n\n' > results-fail.txt
printf 'test=riosodu/qol_bundle/alpha\tfail\n' >> results-fail.txt
check_exit "failing run refuses to write" 1 evidence_write_report main riosodu/qol_bundle results-fail.txt reports-fail qol-bundle
check "failing run writes nothing" "$(test -e reports-fail/qol-bundle.json && echo yes || echo no)" "no"
check "valid evidence unchanged after failing run" "$(jq -c . "$MAIN_REPORT")" "$BEFORE"

printf 'Integration Test Results\n========================\n\nTotal: 1\nPassed: 1\nFailed: 0\nDuration: 0.5s\n\n' > results-partial.txt
printf 'test=riosodu/qol_bundle/alpha\tpass\n' >> results-partial.txt
check_exit "partial run refuses to write" 1 evidence_write_report main riosodu/qol_bundle results-partial.txt test-reports qol-bundle
check "valid evidence unchanged after partial run" "$(jq -c . "$MAIN_REPORT")" "$BEFORE"

# Legacy per-run reports are ignored: the gate only reads <mod>.json.
mkdir -p reports-legacy
printf '{}\n' > "reports-legacy/$(printf '%.12s' "$(git rev-parse HEAD)")-main-riosodu-qol_bundle.json"
check_exit "legacy per-run report ignored" 1 "$CHECKER" --reports-dir reports-legacy qol-bundle

# Unknown mods are rejected loudly.
check_exit "unknown mod rejected" 1 "$CHECKER" not-a-mod

# --- summary -----------------------------------------------------------------
echo
if [ "$failed" -gt 0 ]; then
    echo "$failed/$total test-evidence checks FAILED"
    exit 1
fi
echo "All $total test-evidence checks passed."
