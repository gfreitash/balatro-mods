#!/usr/bin/env bash
# scripts/lib/test-evidence.sh
#
# Test-evidence helpers shared by the runner (scripts/run-integration-tests.sh)
# and the release gate (scripts/check-test-evidence.sh).
#
# Model (deliberately crypto-free): a report is valid evidence for a mod when
# the sha256 fingerprint of the tested content still matches the content being
# released. The fingerprint covers the mod dir + _common/ (minus version
# metadata, so version bumps and changelog edits don't invalidate a report)
# plus the in-game test harness (tools/integration-runner/). Any change to mod
# sources, tests, or the harness invalidates the report until the suite is
# re-run.
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
#   "path<TAB>blob" lines (git blob hashes). Version metadata is excluded
#   (smods.json / manifest.json / CHANGELOG.md anywhere, _common/version.lua)
#   because releases change it without changing behavior.
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
            $2 ~ /(^|\/)(smods\.json|manifest\.json|CHANGELOG\.md)$/ { next }
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

# evidence_pattern_slug PATTERN
#   Filesystem-safe slug for a run pattern ("all" when empty).
evidence_pattern_slug() {
    local slug
    slug="$(printf '%s' "$1" | sed 's/[^A-Za-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
    if [ -z "$slug" ]; then
        slug="all"
    fi
    printf '%s' "$slug"
}

# evidence_write_report MODE PATTERN RESULTS_FILE OUT_DIR MOD_DIR...
#   Writes a balatro-test-evidence/1 JSON report and echoes its path.
#   Fingerprints come from the current working tree; callers are responsible
#   for checking that it still matches what the session was launched with.
evidence_write_report() {
    local mode="$1" pattern="$2" results="$3" out_dir="$4"
    shift 4
    local -a mod_dirs=("$@")
    mkdir -p "$out_dir" || return 1

    local totals tests_json
    if ! totals="$(evidence_results_totals_json "$results")"; then
        log_error "test-evidence: could not parse totals from $results"
        return 1
    fi
    tests_json="$(evidence_tests_json "$results")" || return 1

    local mods_json="{}" mod fp
    for mod in "${mod_dirs[@]}"; do
        if ! fp="$(evidence_mod_fingerprint "$mod")"; then
            log_error "test-evidence: could not fingerprint $mod"
            return 1
        fi
        mods_json="$(jq -c --arg k "$mod" --arg v "$fp" '. + {($k): $v}' <<<"$mods_json")"
    done

    local harness_fp
    if ! harness_fp="$(evidence_harness_fingerprint)"; then
        log_error "test-evidence: could not fingerprint the test harness"
        return 1
    fi

    local head dirty generated out
    head="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
    dirty=false
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        dirty=true
    fi
    generated="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    out="$out_dir/$(printf '%.12s' "$head")-${mode}-$(evidence_pattern_slug "$pattern").json"

    if ! jq -n \
        --arg schema "balatro-test-evidence/1" \
        --arg mode "$mode" \
        --arg pattern "$pattern" \
        --arg generated_at "$generated" \
        --arg git_head "$head" \
        --argjson worktree_dirty "$dirty" \
        --argjson mods "$mods_json" \
        --arg harness "$harness_fp" \
        --argjson totals "$totals" \
        --argjson tests "$tests_json" \
        '{
            schema: $schema,
            mode: $mode,
            pattern: $pattern,
            generated_at: $generated_at,
            git_head: $git_head,
            worktree_dirty: $worktree_dirty,
            hashes: { mods: $mods, harness: $harness },
            totals: $totals,
            tests: $tests
        }' > "$out"; then
        rm -f "$out"
        return 1
    fi
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
