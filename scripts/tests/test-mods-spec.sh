#!/usr/bin/env bash
# scripts/tests/test-mods-spec.sh
#
# Network-free tests for the mod-spec parser in scripts/lib/mods.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/mods.sh
source "$SCRIPT_DIR/../lib/mods.sh"

total=0
failed=0

check() { # DESC ACTUAL EXPECTED
    total=$((total + 1))
    if [ "$2" != "$3" ]; then
        failed=$((failed + 1))
        echo "FAIL: $1: expected '$3', got '$2'"
    fi
}

expect_ok() { # DESC SPEC
    total=$((total + 1))
    if ! mods_spec_parse "$2"; then
        failed=$((failed + 1))
        echo "FAIL: $1: expected parse OK for '$2', got error: $MODS_SPEC_ERROR"
    fi
}

expect_err() { # DESC SPEC
    total=$((total + 1))
    if mods_spec_parse "$2"; then
        failed=$((failed + 1))
        echo "FAIL: $1: expected a parse error for '$2'"
    fi
}

# --- local -------------------------------------------------------------------
expect_ok "local plain" "local:qol-bundle"
check "local dir" "$MODS_SPEC_LOCAL_DIR" "qol-bundle"
check "local scheme" "$MODS_SPEC_SCHEME" "local"
expect_ok "local absolute" "local:/tmp/some-mod"
check "local absolute dir" "$MODS_SPEC_LOCAL_DIR" "/tmp/some-mod"
expect_err "local empty" "local:"
expect_err "no scheme" "qol-bundle"
expect_err "unknown scheme" "npm:foo"

# --- thunderstore ------------------------------------------------------------
expect_ok "ts pinned" "thunderstore:PaperbackedProjects-Paperback@0.9.1"
check "ts ns" "$MODS_SPEC_TS_NS" "PaperbackedProjects"
check "ts name" "$MODS_SPEC_TS_NAME" "Paperback"
check "ts version" "$MODS_SPEC_TS_VERSION" "0.9.1"
expect_ok "ts latest" "thunderstore:Steamodded-Steamodded"
check "ts latest version empty" "$MODS_SPEC_TS_VERSION" ""
expect_ok "ts underscores" "thunderstore:Some_NS-Some_Name"
check "ts underscore ns" "$MODS_SPEC_TS_NS" "Some_NS"
check "ts underscore name" "$MODS_SPEC_TS_NAME" "Some_Name"
expect_err "ts empty version" "thunderstore:A-B@"
expect_err "ts no dash" "thunderstore:NoDash"
expect_err "ts bad chars" "thunderstore:a.b-c"
expect_err "ts empty ns" "thunderstore:-B"

# --- github ------------------------------------------------------------------
expect_ok "gh plain" "github:gfreitash/balatro-mods"
check "gh owner" "$MODS_SPEC_GH_OWNER" "gfreitash"
check "gh repo" "$MODS_SPEC_GH_REPO" "balatro-mods"
check "gh ref empty" "$MODS_SPEC_GH_REF" ""
check "gh subdir empty" "$MODS_SPEC_GH_SUBDIR" ""
expect_ok "gh ref + subdir" "github:gfreitash/balatro-mods@main::qol-bundle/"
check "gh ref" "$MODS_SPEC_GH_REF" "main"
check "gh subdir trailing slash trimmed" "$MODS_SPEC_GH_SUBDIR" "qol-bundle"
expect_ok "gh subdir only" "github:o/r::sub"
check "gh subdir only" "$MODS_SPEC_GH_SUBDIR" "sub"
check "gh ref still empty" "$MODS_SPEC_GH_REF" ""
expect_ok "gh nested subdir" "github:o/r@v1.2.3::a/b/"
check "gh nested subdir" "$MODS_SPEC_GH_SUBDIR" "a/b"
check "gh nested ref" "$MODS_SPEC_GH_REF" "v1.2.3"
expect_err "gh no repo" "github:owner"
expect_err "gh too many slashes" "github:o/r/x"
expect_err "gh empty ref" "github:o/r@"
expect_err "gh absolute subdir" "github:o/r::/abs"
expect_err "gh dotdot subdir" "github:o/r::a/../b"
expect_err "gh empty subdir" "github:o/r::"

# --- github-release ----------------------------------------------------------
expect_ok "ghr full" "github-release:gfreitash/balatro-mods@qol-bundle__v1.12.2#qol-bundle__v1.12.2.zip"
check "ghr owner" "$MODS_SPEC_GHR_OWNER" "gfreitash"
check "ghr repo" "$MODS_SPEC_GHR_REPO" "balatro-mods"
check "ghr tag" "$MODS_SPEC_GHR_TAG" "qol-bundle__v1.12.2"
check "ghr asset" "$MODS_SPEC_GHR_ASSET" "qol-bundle__v1.12.2.zip"
expect_err "ghr no asset" "github-release:o/r@tag"
expect_err "ghr no tag" "github-release:o/r#a.zip"
expect_err "ghr empty tag" "github-release:o/r@#a.zip"
expect_err "ghr empty asset" "github-release:o/r@tag#"

# --- summary -----------------------------------------------------------------
echo
if [ "$failed" -gt 0 ]; then
    echo "$failed/$total spec-parser checks FAILED"
    exit 1
fi
echo "All $total spec-parser checks passed."
