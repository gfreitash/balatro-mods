#!/usr/bin/env bash
# scripts/lib/test-evidence.sh
#
# Test-evidence helpers shared by the runner (scripts/run-integration-tests.sh)
# and the release gate (scripts/check-test-evidence.sh).
#
# Model (deliberately crypto-free): each mod owns a single report at
# test-reports/<mod>.json. The report holds one block per run mode under
# `runs`; each verified run replaces only the block for the mode it covers, so
# the file always describes the latest verified state of that mod.
#
# A block is valid evidence when the sha256 fingerprint of the tested content
# still matches the content being released. The fingerprint covers the mod dir
# + _common/ (minus version metadata, so version bumps and changelog edits
# don't invalidate a report) plus the in-game test harness
# (tools/integration-runner/). Any change to mod sources, tests, or the harness
# invalidates the report until the suite is re-run.
#
# Callers must ensure `git`, `jq` and `sha256sum` are available.
#
# No side effects on source.

# --- logging fallbacks (callers usually define colored versions) -------------
if ! declare -F log_info >/dev/null 2>&1; then
    log_info() { echo "INFO: $*"; }
fi
if ! declare -F log_warn >/dev/null 2>&1; then
    log_warn() { echo "WARN: $*" >&2; }
fi
if ! declare -F log_error >/dev/null 2>&1; then
    log_error() { echo "ERROR: $*" >&2; }
fi
if ! declare -F log_success >/dev/null 2>&1; then
    log_success() { echo "SUCCESS: $*"; }
fi

# --- fingerprints ------------------------------------------------------------

# evidence_fingerprint PATHS...
#   sha256 over the working-tree content of PATHS, canonicalized as sorted
#   "path<TAB>blob" lines (git blob hashes). Version metadata and documentation
#   are excluded (smods.json / manifest.json / *.md anywhere,
#   _common/version.lua) because releases and docs change them without changing
#   behavior.
#   Echoes the hex digest; returns 1 outside a git repo or on git errors.
evidence_fingerprint() {
    [ "$#" -gt 0 ] || return 1
    local tmp index_out digest
    tmp="$(mktemp "${TMPDIR:-/tmp}/test-evidence.XXXXXX")"
    rm -f "$tmp"
    if ! GIT_INDEX_FILE="$tmp" git read-tree HEAD 2>/dev/null; then
        rm -f "$tmp"
        return 1
    fi
    if ! GIT_INDEX_FILE="$tmp" git add -A -- "$@" 2>/dev/null; then
        rm -f "$tmp"
        return 1
    fi
    if ! index_out="$(GIT_INDEX_FILE="$tmp" git ls-files -s -- "$@")"; then
        rm -f "$tmp"
        return 1
    fi
    rm -f "$tmp"
    digest="$(printf '%s\n' "$index_out" \
        | awk -F'\t' '
            $2 ~ /(^|\/)(smods\.json|manifest\.json)$/ { next }
            $2 ~ /\.md$/ { next }
            $2 == "_common/version.lua" { next }
            $1 ~ /^[0-9]+ [0-9a-f]+ [0-9]+$/ { split($1, m, " "); print $2 "\t" m[2] }
        ' \
        | LC_ALL=C sort \
        | sha256sum | cut -d' ' -f1)"
    [ -n "$digest" ] || return 1
    printf '%s' "$digest"
}

# evidence_mod_fingerprint MOD_DIR
#   Fingerprint of a mod's tested content: the mod dir + the shared library.
evidence_mod_fingerprint() {
    local mod_dir="${1%/}"
    evidence_fingerprint "$mod_dir/" "_common/"
}

# evidence_harness_fingerprint
#   Fingerprint of the in-game test harness.
evidence_harness_fingerprint() {
    evidence_fingerprint "tools/integration-runner/"
}

# --- report parsing / writing ------------------------------------------------

# evidence_results_totals_json FILE
#   Echoes {"total":N,"passed":N,"failed":N} from a latest.txt results file.
evidence_results_totals_json() {
    local file="$1" total passed failed
    [ -f "$file" ] || return 1
    total="$(awk -F': ' '/^Total:/{print $2; exit}' "$file")"
    passed="$(awk -F': ' '/^Passed:/{print $2; exit}' "$file")"
    failed="$(awk -F': ' '/^Failed:/{print $2; exit}' "$file")"
    if [ -z "$total" ] || [ -z "$passed" ] || [ -z "$failed" ]; then
        return 1
    fi
    case "${total}${passed}${failed}" in
        *[!0-9]*) return 1 ;;
    esac
    printf '{"total":%s,"passed":%s,"failed":%s}' "$total" "$passed" "$failed"
}

# evidence_tests_json FILE
#   Echoes the per-test array parsed from the harness-written
#   "test=<name><TAB><pass|fail>" lines ([] when none are present).
evidence_tests_json() {
    local file="$1"
    if [ ! -f "$file" ]; then
        printf '[]'
        return 0
    fi
    awk -F'\t' '
        /^test=/ {
            sub(/^test=/, "", $1)
            if ($2 == "pass" || $2 == "fail") print $1 "\t" $2
        }
    ' "$file" \
        | jq -Rn '[inputs | select(length > 0) | split("\t") | {name: .[0], passed: (.[1] == "pass")}]'
}

# evidence_suites_for_mode MOD_DIR MODE
#   Suites required for MOD_DIR in MODE (one per line).
evidence_suites_for_mode() {
    local mod_dir="${1%/}" run_mode="$2" mode suite
    while IFS=$'\t' read -r mode suite; do
        [ -n "$mode" ] || continue
        [ "$mode" = "$run_mode" ] || continue
        printf '%s\n' "$suite"
    done < <(evidence_required_evidence "$mod_dir" || true)
}

# evidence_mode_expected_tests MOD_DIR MODE
#   Test names statically expected for every suite required in MODE.
evidence_mode_expected_tests() {
    local mod_dir="${1%/}" run_mode="$2" suite
    while IFS= read -r suite; do
        [ -n "$suite" ] || continue
        evidence_expected_tests "$mod_dir" "$suite"
    done < <(evidence_suites_for_mode "$mod_dir" "$run_mode") \
        | LC_ALL=C sort -u
}

# evidence_covered_mods MODE PATTERN MOD_DIR...
#   Prints the mods whose required evidence for MODE is fully covered by
#   PATTERN. Mods without required suites in MODE are not printed.
evidence_covered_mods() {
    local run_mode="$1" pattern="$2"
    shift 2
    local mod mode suite any all_covered
    for mod in "$@"; do
        any=0
        all_covered=1
        while IFS=$'\t' read -r mode suite; do
            [ -n "$mode" ] || continue
            [ "$mode" = "$run_mode" ] || continue
            any=1
            if ! evidence_pattern_covers_suite "$mod" "$pattern" "$suite"; then
                all_covered=0
                break
            fi
        done < <(evidence_required_evidence "$mod" || true)
        if [ "$any" = 1 ] && [ "$all_covered" = 1 ]; then
            printf '%s\n' "$mod"
        fi
    done
}

# evidence_report_file OUT_DIR MOD_DIR
#   Canonical report path for a mod.
evidence_report_file() {
    printf '%s/%s.json' "${1%/}" "${2%/}"
}

# evidence_write_report MODE PATTERN RESULTS_FILE OUT_DIR MOD_DIR
#   Records a passing run for one mod in its canonical report, merging
#   `runs[MODE]` into the existing file (other modes are preserved). Echoes the
#   report path. Refuses to write when the run has failures or when any test
#   expected for the mod/mode is missing or failed, so a partial run can never
#   replace valid evidence.
evidence_write_report() {
    local mode="$1" pattern="$2" results="$3" out_dir="$4" mod="${5%/}"
    [ -n "$mod" ] || return 1

    local totals run_failed
    if ! totals="$(evidence_results_totals_json "$results")"; then
        log_error "test-evidence: could not parse totals from $results"
        return 1
    fi
    run_failed="$(jq -r '.failed' <<<"$totals")"
    if [ "$run_failed" != "0" ]; then
        log_error "test-evidence: refusing to record $mod $mode evidence from a run with $run_failed failure(s)"
        return 1
    fi

    local expected expected_json all_tests filtered missing
    expected="$(evidence_mode_expected_tests "$mod" "$mode")"
    if [ -z "$expected" ]; then
        log_error "test-evidence: no tests found for $mod ($mode)"
        return 1
    fi
    expected_json="$(printf '%s\n' "$expected" | jq -R . | jq -s .)"
    all_tests="$(evidence_tests_json "$results")" || return 1
    filtered="$(jq -c --argjson names "$expected_json" \
        'map(select(.name as $n | $names | index($n)))' <<<"$all_tests")"
    missing="$(comm -23 \
        <(printf '%s\n' "$expected" | LC_ALL=C sort -u) \
        <(jq -r '.[] | select(.passed) | .name' <<<"$filtered" | LC_ALL=C sort -u) \
        || true)"
    if [ -n "$missing" ]; then
        log_error "test-evidence: refusing to record $mod $mode evidence; expected test(s) missing or failed:"
        printf '%s\n' "$missing" | sed 's/^/  /' >&2
        return 1
    fi

    local filtered_totals mod_fp harness_fp head dirty generated run_json out tmp
    filtered_totals="$(jq -c '{total: length, passed: (map(select(.passed)) | length), failed: (map(select(.passed | not)) | length)}' <<<"$filtered")"
    if ! mod_fp="$(evidence_mod_fingerprint "$mod")"; then
        log_error "test-evidence: could not fingerprint $mod"
        return 1
    fi
    if ! harness_fp="$(evidence_harness_fingerprint)"; then
        log_error "test-evidence: could not fingerprint the test harness"
        return 1
    fi
    head="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
    dirty=false
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        dirty=true
    fi
    generated="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if ! run_json="$(jq -n \
        --arg mode "$mode" \
        --arg pattern "$pattern" \
        --arg generated_at "$generated" \
        --arg git_head "$head" \
        --argjson worktree_dirty "$dirty" \
        --arg mod "$mod" \
        --arg mod_fp "$mod_fp" \
        --arg harness_fp "$harness_fp" \
        --argjson totals "$filtered_totals" \
        --argjson tests "$filtered" \
        '{
            mode: $mode,
            pattern: $pattern,
            generated_at: $generated_at,
            git_head: $git_head,
            worktree_dirty: $worktree_dirty,
            hashes: { mods: { ($mod): $mod_fp }, harness: $harness_fp },
            totals: $totals,
            tests: $tests
        }')"; then
        log_error "test-evidence: could not build the $mod $mode report"
        return 1
    fi

    mkdir -p "$out_dir" || return 1
    out="$(evidence_report_file "$out_dir" "$mod")"
    tmp="$(mktemp "$out_dir/.${mod}.XXXXXX")" || return 1
    if [ -f "$out" ] && jq -e '.schema == "balatro-test-evidence/2" and (.runs | type == "object")' "$out" >/dev/null 2>&1; then
        jq --arg mode "$mode" --arg mod "$mod" --argjson run "$run_json" \
            '.mod = $mod | .runs[$mode] = $run' "$out" > "$tmp" \
            || { rm -f "$tmp"; return 1; }
    else
        jq -n --arg mode "$mode" --arg mod "$mod" --argjson run "$run_json" \
            '{schema: "balatro-test-evidence/2", mod: $mod, runs: {($mode): $run}}' > "$tmp" \
            || { rm -f "$tmp"; return 1; }
    fi
    mv "$tmp" "$out" || { rm -f "$tmp"; return 1; }
    printf '%s' "$out"
}

# --- coverage / requirements -------------------------------------------------

# evidence_expected_tests MOD_DIR SUITE_PREFIX
#   Test names statically registered in the mod's test sources that start with
#   the suite prefix (one per line, sorted, deduplicated).
evidence_expected_tests() {
    local mod_dir="${1%/}" prefix="$2"
    {
        if [ -f "$mod_dir/tests.lua" ]; then
            cat "$mod_dir/tests.lua"
        fi
        if [ -d "$mod_dir/tests" ]; then
            find "$mod_dir/tests" -type f -name '*.lua' -exec cat {} + 2>/dev/null || true
        fi
    } | grep -oE 'register_test\([[:space:]]*"[^"]+"' 2>/dev/null \
        | sed -E 's/.*"([^"]+)"$/\1/' \
        | awk -v p="$prefix" 'index($0, p) == 1' \
        | LC_ALL=C sort -u \
        || true
}

# evidence_required_evidence MOD_DIR
#   Lines "MODE<TAB>SUITE_PREFIX" describing the evidence a release of
#   MOD_DIR requires. Returns 1 for unknown mod dirs.
evidence_required_evidence() {
    case "${1%/}" in
        qol-bundle)        printf 'main\triosodu/qol_bundle\npb\triosodu/pb\n' ;;
        black-seal)        printf 'main\triosodu/black_seal\n' ;;
        rebalanced-stakes) printf 'main\triosodu/rebalanced_stakes\n' ;;
        *) return 1 ;;
    esac
}

# evidence_known_suites
#   All known suite prefixes (one per line).
evidence_known_suites() {
    printf '%s\n' riosodu/qol_bundle riosodu/black_seal riosodu/rebalanced_stakes riosodu/pb
}

# evidence_pattern_covers_suite MOD_DIR PATTERN SUITE_PREFIX
#   True when every test statically expected for the suite matches the run
#   pattern (BInt matches patterns as plain substrings). An empty pattern
#   matches everything.
evidence_pattern_covers_suite() {
    local mod_dir="${1%/}" pattern="$2" suite="$3"
    local expected name
    expected="$(evidence_expected_tests "$mod_dir" "$suite")"
    [ -n "$expected" ] || return 1
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if [ -n "$pattern" ] && [[ "$name" != *"$pattern"* ]]; then
            return 1
        fi
    done <<<"$expected"
    return 0
}
