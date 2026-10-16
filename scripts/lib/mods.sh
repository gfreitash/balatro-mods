#!/usr/bin/env bash
# scripts/lib/mods.sh
#
# Shared mod setup/teardown library for the integration test harness.
#
# Sourced by scripts/run-integration-tests.sh, scripts/test-mods.sh and
# setup-libs.sh. Provides:
#   - mod spec parsing (local / thunderstore / github / github-release)
#   - cache-first fetching under lib/mods-cache/ (gitignored)
#   - a clean Mods-folder setup: back up what will be wiped (Mods entries +
#     the save dir's config/), wipe everything managed, install exactly the
#     declared mods + harness infra
#   - teardown: restore the backup exactly (Mods entries + config/)
#
# Design notes:
#   - "Clean start" is a setup invariant: every launch begins by wiping all
#     managed entries (everything except lovely/) and installing the declared
#     set, so crashed or failed runs cannot poison the next one.
#   - The backup is reuse-or-create: while a restore is pending, later setups
#     reuse it instead of overwriting it with test-built state.
#   - Nothing outside the Mods folder and the save dir's config/ is touched.
#   - No side effects on source.

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

# --- constants ---------------------------------------------------------------
MODS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODS_REPO_ROOT="$(cd "$MODS_LIB_DIR/../.." && pwd)"
MODS_CACHE_DIR="${MODS_CACHE_DIR:-$MODS_REPO_ROOT/lib/mods-cache}"
MODS_SNAPSHOT_DIR="${MODS_SNAPSHOT_DIR:-$MODS_REPO_ROOT/lib/mod_folder_snapshots}"
MODS_PENDING_FILE="$MODS_SNAPSHOT_DIR/pending"
MODS_SNAPSHOTS_KEEP="${MODS_SNAPSHOTS_KEEP:-3}"

# Behavior switches (set by callers before calling into the library).
MODS_OFFLINE="${MODS_OFFLINE:-0}"
MODS_REFRESH="${MODS_REFRESH:-0}"
MODS_DRY_RUN="${MODS_DRY_RUN:-0}"

# --- small helpers -----------------------------------------------------------

mods_sanitize() { # VALUE -> filesystem-safe token
    printf '%s' "$1" | sed 's/[^A-Za-z0-9._-]/_/g'
}

mods_determine_destination() { # echoes the Balatro Mods directory (or nothing)
    local link_path="$MODS_REPO_ROOT/lib/mod_folder"
    local default_mods_path="$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"

    if [ -L "$link_path" ]; then
        readlink -f "$link_path"
    elif [ -d "$default_mods_path" ]; then
        echo "$default_mods_path"
    else
        echo ""
    fi
}

mods_save_dir() { # MODS_DIR -> echoes the Balatro save dir (parent of Mods)
    local resolved
    resolved="$(readlink -f "$1")"
    dirname "$resolved"
}

mods_default_specs() { # echoes the default content-mod specs, one per line
    find "$MODS_REPO_ROOT" -maxdepth 2 -name "smods.json" ! -path '*/_common/*' ! -path '*/lib/*' -exec dirname {} \; \
        | sed "s|^$MODS_REPO_ROOT/||" \
        | sort \
        | sed 's|^|local:|'
}

mods_manifest_name() { # DIR -> destination folder name (manifest .name or basename)
    local dir="$1" name=""
    if [ -f "$dir/manifest.json" ]; then
        name="$(jq -r '.name // empty' "$dir/manifest.json" 2>/dev/null || true)"
    fi
    if [ -z "$name" ]; then
        name="$(basename "$dir")"
    fi
    printf '%s' "$name"
}

# --- spec parsing ------------------------------------------------------------
# Grammar:
#   local:<dir>
#   thunderstore:<ns>-<name>[@<version>]
#   github:<owner>/<repo>[@<ref>][::<subdir>]
#   github-release:<owner>/<repo>@<tag>#<asset>
#
# mods_spec_parse SPEC
#   Fills MODS_SPEC_SCHEME + scheme fields; returns 1 and sets MODS_SPEC_ERROR
#   on invalid input. Fields are cleared first.
mods_spec_parse() {
    local raw="$1"
    MODS_SPEC_RAW="$raw"
    MODS_SPEC_ERROR=""
    MODS_SPEC_SCHEME=""
    MODS_SPEC_LOCAL_DIR=""
    MODS_SPEC_TS_NS=""; MODS_SPEC_TS_NAME=""; MODS_SPEC_TS_VERSION=""
    MODS_SPEC_GH_OWNER=""; MODS_SPEC_GH_REPO=""; MODS_SPEC_GH_REF=""; MODS_SPEC_GH_SUBDIR=""
    MODS_SPEC_GHR_OWNER=""; MODS_SPEC_GHR_REPO=""; MODS_SPEC_GHR_TAG=""; MODS_SPEC_GHR_ASSET=""

    if [[ "$raw" != *:* || "$raw" == :* ]]; then
        MODS_SPEC_ERROR="missing '<scheme>:' prefix"
        return 1
    fi
    MODS_SPEC_SCHEME="${raw%%:*}"
    local rest="${raw#*:}"
    [ -n "$rest" ] || { MODS_SPEC_ERROR="empty spec after '<scheme>:'"; return 1; }

    case "$MODS_SPEC_SCHEME" in
        local)
            MODS_SPEC_LOCAL_DIR="$rest"
            ;;
        thunderstore)
            local namepart="$rest" version=""
            if [[ "$rest" == *@* ]]; then
                namepart="${rest%@*}"
                version="${rest##*@}"
                [ -n "$version" ] || { MODS_SPEC_ERROR="empty version after '@'"; return 1; }
            fi
            if [[ "$namepart" != *-* ]]; then
                MODS_SPEC_ERROR="expected '<namespace>-<name>'"
                return 1
            fi
            MODS_SPEC_TS_NS="${namepart%%-*}"
            MODS_SPEC_TS_NAME="${namepart#*-}"
            if ! [[ "$MODS_SPEC_TS_NS" =~ ^[A-Za-z0-9_]+$ && "$MODS_SPEC_TS_NAME" =~ ^[A-Za-z0-9_]+$ ]]; then
                MODS_SPEC_ERROR="namespace/name may only contain letters, digits and '_'"
                return 1
            fi
            MODS_SPEC_TS_VERSION="$version"
            ;;
        github)
            local repo_part="$rest"
            if [[ "$repo_part" == *"::"* ]]; then
                MODS_SPEC_GH_SUBDIR="${repo_part##*::}"
                repo_part="${repo_part%%::*}"
                MODS_SPEC_GH_SUBDIR="${MODS_SPEC_GH_SUBDIR%/}"
                [ -n "$MODS_SPEC_GH_SUBDIR" ] || { MODS_SPEC_ERROR="empty subdir after '::'"; return 1; }
                if [[ "$MODS_SPEC_GH_SUBDIR" == /* || "$MODS_SPEC_GH_SUBDIR" == *..* ]]; then
                    MODS_SPEC_ERROR="subdir must be relative and must not contain '..'"
                    return 1
                fi
            fi
            if [[ "$repo_part" == *@* ]]; then
                MODS_SPEC_GH_REF="${repo_part##*@}"
                repo_part="${repo_part%@*}"
                [ -n "$MODS_SPEC_GH_REF" ] || { MODS_SPEC_ERROR="empty ref after '@'"; return 1; }
            fi
            if [[ "$repo_part" != */* ]]; then
                MODS_SPEC_ERROR="expected '<owner>/<repo>'"
                return 1
            fi
            MODS_SPEC_GH_OWNER="${repo_part%%/*}"
            MODS_SPEC_GH_REPO="${repo_part#*/}"
            if [[ -z "$MODS_SPEC_GH_OWNER" || -z "$MODS_SPEC_GH_REPO" || "$MODS_SPEC_GH_REPO" == */* ]]; then
                MODS_SPEC_ERROR="expected exactly '<owner>/<repo>'"
                return 1
            fi
            ;;
        github-release)
            if [[ "$rest" != *"#"* ]]; then
                MODS_SPEC_ERROR="expected '<owner>/<repo>@<tag>#<asset>' (missing '#<asset>')"
                return 1
            fi
            MODS_SPEC_GHR_ASSET="${rest##*#}"
            local repo_tag="${rest%%#*}"
            [ -n "$MODS_SPEC_GHR_ASSET" ] || { MODS_SPEC_ERROR="empty asset after '#'"; return 1; }
            if [[ "$repo_tag" != *@* ]]; then
                MODS_SPEC_ERROR="expected '<owner>/<repo>@<tag>' (missing '@<tag>')"
                return 1
            fi
            MODS_SPEC_GHR_TAG="${repo_tag##*@}"
            repo_tag="${repo_tag%@*}"
            [ -n "$MODS_SPEC_GHR_TAG" ] || { MODS_SPEC_ERROR="empty tag after '@'"; return 1; }
            if [[ "$repo_tag" != */* ]]; then
                MODS_SPEC_ERROR="expected '<owner>/<repo>'"
                return 1
            fi
            MODS_SPEC_GHR_OWNER="${repo_tag%%/*}"
            MODS_SPEC_GHR_REPO="${repo_tag#*/}"
            if [[ -z "$MODS_SPEC_GHR_OWNER" || -z "$MODS_SPEC_GHR_REPO" || "$MODS_SPEC_GHR_REPO" == */* ]]; then
                MODS_SPEC_ERROR="expected exactly '<owner>/<repo>'"
                return 1
            fi
            ;;
        *)
            MODS_SPEC_ERROR="unknown scheme '$MODS_SPEC_SCHEME' (expected local, thunderstore, github or github-release)"
            return 1
            ;;
    esac
    return 0
}

# --- fetching (cache-first) --------------------------------------------------

mods_ts_pkg_dir() {
    printf '%s/thunderstore/%s-%s' "$MODS_CACHE_DIR" "$MODS_SPEC_TS_NS" "$MODS_SPEC_TS_NAME"
}

# Resolves the version to install (pinned or latest); sets MODS_TS_VERSION.
mods_ts_resolve_version() {
    MODS_TS_VERSION=""
    if [ -n "$MODS_SPEC_TS_VERSION" ]; then
        MODS_TS_VERSION="$MODS_SPEC_TS_VERSION"
        return 0
    fi
    local pkg_dir latest_file version=""
    pkg_dir="$(mods_ts_pkg_dir)"
    latest_file="$pkg_dir/latest.json"

    if [ "$MODS_OFFLINE" != 1 ]; then
        version="$(curl -fsSL --retry 2 "https://thunderstore.io/api/experimental/package/$MODS_SPEC_TS_NS/$MODS_SPEC_TS_NAME/" 2>/dev/null \
            | jq -r '.latest.version_number // empty' 2>/dev/null || true)"
    fi
    if [ -n "$version" ]; then
        if [ "$MODS_DRY_RUN" != 1 ]; then
            mkdir -p "$pkg_dir"
            printf '{"version":"%s","resolved_at":"%s"}\n' "$version" "$(date -Iseconds)" > "$latest_file"
        fi
        MODS_TS_VERSION="$version"
        return 0
    fi
    if [ -f "$latest_file" ]; then
        [ "$MODS_OFFLINE" = 1 ] || log_warn "Could not reach Thunderstore; using cached latest version for $MODS_SPEC_TS_NS-$MODS_SPEC_TS_NAME"
        MODS_TS_VERSION="$(jq -r '.version' "$latest_file")"
        return 0
    fi
    MODS_SPEC_ERROR="could not resolve the latest version for $MODS_SPEC_TS_NS-$MODS_SPEC_TS_NAME"
    return 1
}

# Ensures the resolved version is extracted in the cache; sets MODS_TS_FETCH_DIR.
mods_ts_fetch() {
    local version target
    mods_ts_resolve_version || return 1
    version="$MODS_TS_VERSION"
    target="$(mods_ts_pkg_dir)/$version"

    if [ "$MODS_REFRESH" != 1 ] && [ -f "$target/manifest.json" ]; then
        MODS_TS_FETCH_DIR="$target"
        return 0
    fi
    if [ "$MODS_OFFLINE" = 1 ]; then
        MODS_SPEC_ERROR="offline: $MODS_SPEC_TS_NS-$MODS_SPEC_TS_NAME@$version is not cached"
        return 1
    fi

    log_info "Fetching thunderstore:$MODS_SPEC_TS_NS-$MODS_SPEC_TS_NAME@$version..."
    local url="https://thunderstore.io/package/download/$MODS_SPEC_TS_NS/$MODS_SPEC_TS_NAME/$version/"
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/mods-fetch.XXXXXX")"
    if ! curl -fsSL --retry 3 -o "$tmp/pkg.zip" "$url"; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="download failed: $url"
        return 1
    fi
    mkdir -p "$tmp/extract"
    if ! unzip -oq "$tmp/pkg.zip" -d "$tmp/extract"; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="unzip failed for $url"
        return 1
    fi
    if [ ! -f "$tmp/extract/manifest.json" ]; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="package has no manifest.json: $url"
        return 1
    fi
    local got
    got="$(jq -r '.version_number // .version // empty' "$tmp/extract/manifest.json" 2>/dev/null || true)"
    if [ -n "$got" ] && [ "$got" != "$version" ]; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="version mismatch for $MODS_SPEC_TS_NS-$MODS_SPEC_TS_NAME: expected $version, got $got"
        return 1
    fi
    rm -rf "$target"
    mkdir -p "$target"
    cp -a "$tmp/extract/." "$target/"
    rm -rf "$tmp"
    MODS_TS_FETCH_DIR="$target"
    return 0
}

mods_gh_repo_dir() {
    printf '%s/github/%s-%s' "$MODS_CACHE_DIR" "$MODS_SPEC_GH_OWNER" "$MODS_SPEC_GH_REPO"
}

mods_gh_api() { # PATH
    local url="https://api.github.com$1"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" "$url"
    else
        curl -fsSL -H "Accept: application/vnd.github+json" "$url"
    fi
}

# Resolves the ref (or default branch) to a commit SHA; sets MODS_GH_SHA.
mods_gh_resolve_sha() {
    local repo_dir ref ref_file
    MODS_GH_SHA=""
    repo_dir="$(mods_gh_repo_dir)"
    ref="${MODS_SPEC_GH_REF:-HEAD}"
    ref_file="$repo_dir/refs/$(mods_sanitize "$ref")"

    if [ "$MODS_OFFLINE" = 1 ]; then
        if [ -f "$ref_file" ]; then
            MODS_GH_SHA="$(cat "$ref_file")"
            return 0
        fi
        MODS_SPEC_ERROR="offline: no cached resolution for $MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO@$ref"
        return 1
    fi
    if [ "$MODS_REFRESH" != 1 ] && [ -f "$ref_file" ]; then
        MODS_GH_SHA="$(cat "$ref_file")"
        return 0
    fi

    local sha
    sha="$(mods_gh_api "/repos/$MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO/commits/$ref" 2>/dev/null \
        | jq -r '.sha // empty' 2>/dev/null || true)"
    if [ -z "$sha" ]; then
        if [ -f "$ref_file" ]; then
            log_warn "Could not resolve $MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO@$ref on GitHub; using cached $(cat "$ref_file")"
            MODS_GH_SHA="$(cat "$ref_file")"
            return 0
        fi
        MODS_SPEC_ERROR="could not resolve $MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO@$ref (check the repo/ref and GITHUB_TOKEN)"
        return 1
    fi
    if [ "$MODS_DRY_RUN" != 1 ]; then
        mkdir -p "$repo_dir/refs"
        printf '%s\n' "$sha" > "$ref_file"
    fi
    MODS_GH_SHA="$sha"
    return 0
}

# Ensures the repo snapshot for the resolved SHA is extracted; sets MODS_GH_SNAPSHOT.
mods_gh_fetch() {
    local sha repo_dir snapshot
    MODS_GH_SNAPSHOT=""
    mods_gh_resolve_sha || return 1
    sha="$MODS_GH_SHA"
    repo_dir="$(mods_gh_repo_dir)"
    snapshot="$repo_dir/$sha"

    if [ "$MODS_REFRESH" != 1 ] && [ -d "$snapshot" ] && [ -n "$(ls -A "$snapshot" 2>/dev/null)" ]; then
        MODS_GH_SNAPSHOT="$snapshot"
        return 0
    fi
    if [ "$MODS_OFFLINE" = 1 ]; then
        MODS_SPEC_ERROR="offline: github:$MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO@$sha is not cached"
        return 1
    fi

    log_info "Fetching github:$MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO@$sha..."
    local url="https://codeload.github.com/$MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO/zip/$sha"
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/mods-fetch.XXXXXX")"
    if ! curl -fsSL --retry 3 -o "$tmp/repo.zip" "$url"; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="download failed: $url"
        return 1
    fi
    mkdir -p "$tmp/extract"
    if ! unzip -oq "$tmp/repo.zip" -d "$tmp/extract"; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="unzip failed for $url"
        return 1
    fi
    local top
    top="$(find "$tmp/extract" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    if [ -z "$top" ]; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="unexpected archive layout: $url"
        return 1
    fi
    rm -rf "$snapshot"
    mkdir -p "$snapshot"
    cp -a "$top/." "$snapshot/"
    rm -rf "$tmp"
    MODS_GH_SNAPSHOT="$snapshot"
    return 0
}

mods_ghr_dir() {
    printf '%s/github-release/%s-%s/%s/%s' "$MODS_CACHE_DIR" "$MODS_SPEC_GHR_OWNER" "$MODS_SPEC_GHR_REPO" \
        "$(mods_sanitize "$MODS_SPEC_GHR_TAG")" "$(mods_sanitize "$MODS_SPEC_GHR_ASSET")"
}

# Ensures the release asset is extracted; sets MODS_GHR_FETCH_DIR.
mods_ghr_fetch() {
    local dir
    MODS_GHR_FETCH_DIR=""
    dir="$(mods_ghr_dir)"
    if [ "$MODS_REFRESH" != 1 ] && [ -f "$dir/manifest.json" ]; then
        MODS_GHR_FETCH_DIR="$dir"
        return 0
    fi
    if [ "$MODS_OFFLINE" = 1 ]; then
        MODS_SPEC_ERROR="offline: github-release:$MODS_SPEC_GHR_OWNER/$MODS_SPEC_GHR_REPO@$MODS_SPEC_GHR_TAG#$MODS_SPEC_GHR_ASSET is not cached"
        return 1
    fi

    log_info "Fetching github-release:$MODS_SPEC_GHR_OWNER/$MODS_SPEC_GHR_REPO@$MODS_SPEC_GHR_TAG#$MODS_SPEC_GHR_ASSET..."
    local url="https://github.com/$MODS_SPEC_GHR_OWNER/$MODS_SPEC_GHR_REPO/releases/download/$MODS_SPEC_GHR_TAG/$MODS_SPEC_GHR_ASSET"
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/mods-fetch.XXXXXX")"
    if ! curl -fsSL --retry 3 -o "$tmp/asset.zip" "$url"; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="download failed: $url (available assets: https://github.com/$MODS_SPEC_GHR_OWNER/$MODS_SPEC_GHR_REPO/releases/tag/$MODS_SPEC_GHR_TAG)"
        return 1
    fi
    mkdir -p "$tmp/extract"
    if ! unzip -oq "$tmp/asset.zip" -d "$tmp/extract"; then
        rm -rf "$tmp"
        MODS_SPEC_ERROR="unzip failed for $url"
        return 1
    fi
    rm -rf "$dir"
    mkdir -p "$dir"
    cp -a "$tmp/extract/." "$dir/"
    rm -rf "$tmp"
    MODS_GHR_FETCH_DIR="$dir"
    return 0
}

# --- resolution --------------------------------------------------------------
# mods_resolve_spec SPEC
#   Fetches/resolves the spec. Sets:
#     MODS_RESOLVED_SRC       directory to install from
#     MODS_RESOLVED_ROOT      repo root for _common bundling ("" = none)
#     MODS_RESOLVED_DEST      destination folder name
#     MODS_RESOLVED_CACHE_HIT 1 when no network fetch was needed
#   With MODS_DRY_RUN=1 nothing is downloaded or written; cache state is
#   reported via MODS_RESOLVED_CACHE_HIT.
#   Returns 1 with MODS_SPEC_ERROR set on failure.
mods_resolve_spec() {
    local spec="$1"
    MODS_SPEC_ERROR=""
    MODS_RESOLVED_SRC=""
    MODS_RESOLVED_ROOT=""
    MODS_RESOLVED_DEST=""
    MODS_RESOLVED_CACHE_HIT=0

    mods_spec_parse "$spec" || return 1
    local dry="$MODS_DRY_RUN"

    case "$MODS_SPEC_SCHEME" in
        local)
            MODS_RESOLVED_SRC="$(mods_local_dir)"
            if [ ! -d "$MODS_RESOLVED_SRC" ]; then
                MODS_SPEC_ERROR="local dir not found: $MODS_RESOLVED_SRC"
                return 1
            fi
            if [ ! -f "$MODS_RESOLVED_SRC/smods.json" ]; then
                MODS_SPEC_ERROR="local dir has no smods.json: $MODS_RESOLVED_SRC"
                return 1
            fi
            MODS_RESOLVED_ROOT="$(dirname "$MODS_RESOLVED_SRC")"
            MODS_RESOLVED_DEST="$(mods_manifest_name "$MODS_RESOLVED_SRC")"
            MODS_RESOLVED_CACHE_HIT=1
            ;;
        thunderstore)
            local cache_dir
            mods_ts_resolve_version || return 1
            local version="$MODS_TS_VERSION"
            cache_dir="$(mods_ts_pkg_dir)/$version"
            if [ "$dry" = 1 ]; then
                MODS_RESOLVED_SRC="$cache_dir"
                if [ -f "$cache_dir/manifest.json" ]; then
                    MODS_RESOLVED_CACHE_HIT=1
                    MODS_RESOLVED_DEST="$(mods_manifest_name "$cache_dir")"
                else
                    MODS_RESOLVED_DEST="(from manifest after fetch)"
                fi
                return 0
            fi
            mods_ts_fetch || return 1
            MODS_RESOLVED_SRC="$MODS_TS_FETCH_DIR"
            MODS_RESOLVED_ROOT=""
            MODS_RESOLVED_DEST="$(mods_manifest_name "$MODS_RESOLVED_SRC")"
            MODS_RESOLVED_CACHE_HIT=1
            ;;
        github)
            local sha repo_dir snapshot src
            mods_gh_resolve_sha || return 1
            sha="$MODS_GH_SHA"
            repo_dir="$(mods_gh_repo_dir)"
            snapshot="$repo_dir/$sha"
            if [ "$dry" = 1 ]; then
                src="$snapshot"
                [ -n "$MODS_SPEC_GH_SUBDIR" ] && src="$snapshot/$MODS_SPEC_GH_SUBDIR"
                MODS_RESOLVED_SRC="$src"
                if [ -f "$src/smods.json" ]; then
                    MODS_RESOLVED_CACHE_HIT=1
                    MODS_RESOLVED_DEST="$(mods_manifest_name "$src")"
                else
                    MODS_RESOLVED_DEST="(from manifest after fetch)"
                fi
                return 0
            fi
            mods_gh_fetch || return 1
            snapshot="$MODS_GH_SNAPSHOT"
            src="$snapshot"
            if [ -n "$MODS_SPEC_GH_SUBDIR" ]; then
                if [ ! -d "$snapshot/$MODS_SPEC_GH_SUBDIR" ]; then
                    MODS_SPEC_ERROR="subdir '$MODS_SPEC_GH_SUBDIR' not found in $MODS_SPEC_GH_OWNER/$MODS_SPEC_GH_REPO@$sha"
                    return 1
                fi
                src="$snapshot/$MODS_SPEC_GH_SUBDIR"
            fi
            if [ ! -f "$src/smods.json" ]; then
                MODS_SPEC_ERROR="no smods.json in github source '$spec'"
                return 1
            fi
            MODS_RESOLVED_SRC="$src"
            MODS_RESOLVED_ROOT="$snapshot"
            MODS_RESOLVED_DEST="$(mods_manifest_name "$src")"
            MODS_RESOLVED_CACHE_HIT=1
            ;;
        github-release)
            local dir
            dir="$(mods_ghr_dir)"
            if [ "$dry" = 1 ]; then
                MODS_RESOLVED_SRC="$dir"
                if [ -f "$dir/manifest.json" ]; then
                    MODS_RESOLVED_CACHE_HIT=1
                    MODS_RESOLVED_DEST="$(mods_manifest_name "$dir")"
                else
                    MODS_RESOLVED_DEST="(from manifest after fetch)"
                fi
                return 0
            fi
            mods_ghr_fetch || return 1
            MODS_RESOLVED_SRC="$MODS_GHR_FETCH_DIR"
            if [ ! -f "$MODS_RESOLVED_SRC/smods.json" ]; then
                MODS_SPEC_ERROR="no smods.json in github-release asset '$spec'"
                return 1
            fi
            MODS_RESOLVED_ROOT=""
            MODS_RESOLVED_DEST="$(mods_manifest_name "$MODS_RESOLVED_SRC")"
            MODS_RESOLVED_CACHE_HIT=1
            ;;
    esac
    return 0
}

mods_local_dir() { # echoes the absolute local source dir
    if [[ "$MODS_SPEC_LOCAL_DIR" == /* ]]; then
        printf '%s' "$MODS_SPEC_LOCAL_DIR"
    else
        printf '%s/%s' "$MODS_REPO_ROOT" "$MODS_SPEC_LOCAL_DIR"
    fi
}

# Public helper: fetch a spec into the cache without installing it.
# Sets MODS_RESOLVED_* (see mods_resolve_spec). Used by setup-libs.sh.
mods_fetch_spec() {
    MODS_DRY_RUN=0
    mods_resolve_spec "$1" || return 1
    return 0
}

# --- install -----------------------------------------------------------------

mods_bundle_common() { # REPO_ROOT DEST_DIR
    local root="$1" dest="$2"
    if [ -z "$root" ] || [ ! -d "$root/_common" ]; then
        return 0
    fi
    rsync -a --delete "$root/_common/" "$dest/common/"
    if [ -d "$root/_common/lovely" ]; then
        mkdir -p "$dest/lovely"
        local f
        for f in "$root/_common/lovely/"*.toml; do
            [ -f "$f" ] || continue
            cp "$f" "$dest/lovely/common_$(basename "$f")"
        done
    fi
    return 0
}

mods_install_resolved() { # MODS_DIR  (uses MODS_RESOLVED_*)
    local mods_dir="$1"
    local dest="$mods_dir/$MODS_RESOLVED_DEST"
    rsync -a --delete --exclude='*.tmp' "$MODS_RESOLVED_SRC/" "$dest/" || return 1
    mods_bundle_common "$MODS_RESOLVED_ROOT" "$dest" || return 1
    return 0
}

mods_install_infra() { # MODS_DIR
    local mods_dir="$1"
    if [ ! -d "$MODS_REPO_ROOT/lib/smods" ]; then
        log_error "Steamodded not found at lib/smods. Run ./setup-libs.sh first."
        return 1
    fi
    rsync -a --delete "$MODS_REPO_ROOT/lib/smods/" "$mods_dir/smods/" || return 1
    if [ ! -d "$MODS_REPO_ROOT/lib/BalatroIntegration" ]; then
        log_error "BalatroIntegration not found at lib/BalatroIntegration. Run ./setup-libs.sh first."
        return 1
    fi
    rsync -a --delete --exclude='.git' --exclude='results' "$MODS_REPO_ROOT/lib/BalatroIntegration/" "$mods_dir/BalatroIntegration/" || return 1
    rsync -a --delete "$MODS_REPO_ROOT/tools/integration-runner/" "$mods_dir/integration_runner/" || return 1
    return 0
}

# --- backup / restore --------------------------------------------------------

mods_guard_destination() { # MODS_DIR
    local mods_dir="$1"
    if [ -z "$mods_dir" ] || [ ! -d "$mods_dir" ]; then
        log_error "Mods folder not found: '$mods_dir'"
        return 1
    fi
    local resolved
    resolved="$(readlink -f "$mods_dir")"
    if [ "$resolved" = "/" ] || [ "$resolved" = "$HOME" ] || [ "$resolved" = "$MODS_REPO_ROOT" ]; then
        log_error "Refusing to manage suspicious path: $resolved"
        return 1
    fi
    if [ "$(basename "$resolved")" != "Mods" ] && [ "${MODS_ALLOW_NONSTD_DEST:-0}" != 1 ]; then
        log_error "Refusing to manage '$resolved' (basename is not 'Mods'); set MODS_ALLOW_NONSTD_DEST=1 to override"
        return 1
    fi
    return 0
}

mods_backup_create() { # MODS_DIR SAVE_DIR BACKUP_DIR
    local mods_dir="$1" save_dir="$2" backup="$3"
    mkdir -p "$backup/mods" || return 1
    local entry base
    while IFS= read -r -d '' entry; do
        base="$(basename "$entry")"
        [ "$base" = "lovely" ] && continue
        rm -rf "$backup/mods/$base"
        if ! cp -a "$entry" "$backup/mods/$base"; then
            log_error "Could not back up $entry"
            return 1
        fi
    done < <(find "$mods_dir" -mindepth 1 -maxdepth 1 -print0)

    if [ -d "$save_dir/config" ]; then
        rm -rf "$backup/config"
        cp -a "$save_dir/config" "$backup/config" || return 1
    fi

    {
        echo "created_at=$(date -Iseconds)"
        echo "mods_dir=$mods_dir"
        echo "save_dir=$save_dir"
        echo "entries:"
        (cd "$backup/mods" && find . -mindepth 1 -maxdepth 1 | sed 's|^\./||' | sort)
    } > "$backup/manifest.txt"
    return 0
}

mods_clean() { # MODS_DIR
    local mods_dir="$1"
    mods_guard_destination "$mods_dir" || return 1
    find "$mods_dir" -mindepth 1 -maxdepth 1 ! -name lovely -exec rm -rf {} + || return 1
    return 0
}

mods_restore() { # MODS_DIR SAVE_DIR BACKUP_DIR
    local mods_dir="$1" save_dir="$2" backup="$3"
    if [ ! -d "$backup" ] || [ ! -d "$backup/mods" ]; then
        log_error "Backup not found or incomplete: $backup"
        return 1
    fi
    mods_guard_destination "$mods_dir" || return 1
    mods_clean "$mods_dir" || return 1
    if ! cp -a "$backup/mods/." "$mods_dir/"; then
        log_error "Failed to restore Mods entries from $backup"
        return 1
    fi
    # Config: restore exactly what existed before (deletes test-created files).
    if [ -d "$backup/config" ]; then
        rm -rf "$save_dir/config"
        if ! cp -a "$backup/config" "$save_dir/config"; then
            log_error "Failed to restore config from $backup"
            return 1
        fi
    else
        rm -rf "$save_dir/config"
    fi
    return 0
}

# --- pending backup / session stamp -----------------------------------------

mods_pending_get() {
    if [ -f "$MODS_PENDING_FILE" ]; then
        cat "$MODS_PENDING_FILE"
    fi
}

mods_pending_set() { # BACKUP_DIR
    mkdir -p "$MODS_SNAPSHOT_DIR"
    printf '%s\n' "$1" > "$MODS_PENDING_FILE"
}

mods_pending_clear() {
    rm -f "$MODS_PENDING_FILE"
}

mods_prune_snapshots() {
    [ -d "$MODS_SNAPSHOT_DIR" ] || return 0
    local pending dirs dir count=0
    pending="$(mods_pending_get)"
    dirs="$(ls -1dt "$MODS_SNAPSHOT_DIR"/*/ 2>/dev/null || true)"
    for dir in $dirs; do
        dir="${dir%/}"
        [ "$dir" = "$pending" ] && continue
        count=$((count + 1))
        if [ "$count" -gt "$MODS_SNAPSHOTS_KEEP" ]; then
            rm -rf "$dir"
        fi
    done
    return 0
}

mods_session_stamp_write() { # MODS_DIR SAVE_DIR BACKUP PB_FLAG SPECS...
    local mods_dir="$1" save_dir="$2" backup="$3" pb="$4"
    shift 4
    local joined="" s
    for s in "$@"; do
        joined="${joined:+$joined,}$s"
    done
    mkdir -p "$mods_dir/integration_runner"
    {
        echo "launched_at=$(date -Iseconds)"
        echo "mods_dir=$mods_dir"
        echo "save_dir=$save_dir"
        echo "backup=$backup"
        echo "pb=$pb"
        echo "mods=$joined"
    } > "$mods_dir/integration_runner/session.txt"
}

# --- setup / teardown --------------------------------------------------------

mods_setup_rollback() {
    [ "${MODS_ROLLED_BACK:-0}" = 1 ] && return 0
    MODS_ROLLED_BACK=1
    trap - EXIT INT TERM
    log_warn "Setup failed or was interrupted — rolling back to the pre-run state..."
    if mods_restore "${MODS_MODS_DIR:-}" "${MODS_SAVE_DIR:-}" "${MODS_BACKUP_DIR:-}"; then
        mods_pending_clear
        log_success "Pre-run state restored from $MODS_BACKUP_DIR"
    else
        log_error "Rollback restore failed; the backup is kept at $MODS_BACKUP_DIR"
    fi
}

# mods_setup MODS_DIR SAVE_DIR SPECS...
#   Resolves + fetches all specs (Mods folder untouched), creates or reuses the
#   pending backup, then wipes and installs infra + specs.
#   On success sets MODS_BACKUP_DIR / MODS_PENDING_REUSED.
mods_setup() {
    local mods_dir="$1" save_dir="$2"
    shift 2
    local -a specs=("$@")
    mods_guard_destination "$mods_dir" || return 1

    MODS_MODS_DIR="$mods_dir"
    MODS_SAVE_DIR="$save_dir"
    MODS_ROLLED_BACK=0

    # Phase 1: resolve + fetch (Mods folder untouched).
    MODS_PHASE=fetch
    local -a srcs=() roots=() dests=()
    local spec
    for spec in "${specs[@]}"; do
        if ! mods_resolve_spec "$spec"; then
            log_error "Spec '$spec': $MODS_SPEC_ERROR"
            return 1
        fi
        local dest="$MODS_RESOLVED_DEST" existing
        for existing in "${dests[@]}"; do
            if [ "$existing" = "$dest" ]; then
                log_error "Spec '$spec': destination '$dest' collides with another spec"
                return 1
            fi
        done
        case "$dest" in
            smods|BalatroIntegration|integration_runner|lovely)
                log_error "Spec '$spec': destination '$dest' is reserved for harness infrastructure"
                return 1
                ;;
        esac
        srcs+=("$MODS_RESOLVED_SRC")
        roots+=("$MODS_RESOLVED_ROOT")
        dests+=("$dest")
        log_info "Resolved $spec -> Mods/$dest"
    done

    # Phase 2: backup (reuse-or-create; never overwrite a pending backup).
    MODS_PHASE=backup
    local pending
    pending="$(mods_pending_get)"
    if [ -n "$pending" ] && [ -d "$pending" ]; then
        MODS_BACKUP_DIR="$pending"
        MODS_PENDING_REUSED=1
        log_info "Reusing pending backup from a previous setup: $pending"
    else
        MODS_BACKUP_DIR="$MODS_SNAPSHOT_DIR/$(date +%Y%m%d-%H%M%S)"
        MODS_PENDING_REUSED=0
        mkdir -p "$MODS_BACKUP_DIR"
        if ! mods_backup_create "$mods_dir" "$save_dir" "$MODS_BACKUP_DIR"; then
            log_error "Backup failed; aborting before touching the Mods folder."
            rm -rf "$MODS_BACKUP_DIR"
            return 1
        fi
        mods_pending_set "$MODS_BACKUP_DIR"
        log_info "Backed up the current Mods folder and configs to $MODS_BACKUP_DIR"
    fi
    mods_prune_snapshots

    # Phase 3: destructive (clean + install), rollback on failure/interrupt.
    trap 'mods_setup_rollback' EXIT
    trap 'exit 130' INT TERM
    MODS_PHASE=destructive

    if ! mods_clean "$mods_dir"; then
        mods_setup_rollback
        return 1
    fi
    if [ "${MODS_TEST_ABORT_AFTER:-}" = "clean" ]; then
        log_warn "(test hook) aborting after clean"
        mods_setup_rollback
        return 1
    fi
    if ! mods_install_infra "$mods_dir"; then
        mods_setup_rollback
        return 1
    fi
    local i
    for i in "${!specs[@]}"; do
        MODS_RESOLVED_SRC="${srcs[$i]}"
        MODS_RESOLVED_ROOT="${roots[$i]}"
        MODS_RESOLVED_DEST="${dests[$i]}"
        if ! mods_install_resolved "$mods_dir"; then
            log_error "Failed to install '${specs[$i]}'"
            mods_setup_rollback
            return 1
        fi
        log_info "Installed ${specs[$i]} -> Mods/${dests[$i]}"
    done

    mods_session_stamp_write "$mods_dir" "$save_dir" "$MODS_BACKUP_DIR" "${MODS_PB_FLAG:-0}" "${specs[@]}"
    MODS_PHASE=done
    trap - EXIT INT TERM
    return 0
}

# mods_plan MODS_DIR SAVE_DIR SPECS...
#   Prints what mods_setup would do; writes nothing (network reads only).
mods_plan() {
    local mods_dir="$1" save_dir="$2"
    shift 2
    local -a specs=("$@")
    local rc=0

    echo "target:   $mods_dir"
    echo "save:     $save_dir"
    echo "infra:    smods (lib/smods) -> Mods/smods"
    echo "          BalatroIntegration (lib/BalatroIntegration) -> Mods/BalatroIntegration"
    echo "          integration_runner -> Mods/integration_runner"

    local spec label
    for spec in "${specs[@]}"; do
        MODS_DRY_RUN=1
        if ! mods_resolve_spec "$spec"; then
            echo "mods:     $spec -> ERROR: $MODS_SPEC_ERROR"
            rc=1
            continue
        fi
        if [ "$MODS_SPEC_SCHEME" = "local" ]; then
            label="rsync from tree"
        elif [ "${MODS_RESOLVED_CACHE_HIT:-0}" = 1 ]; then
            label="cache HIT"
        else
            label="cache MISS; would fetch"
        fi
        echo "mods:     $spec -> Mods/$MODS_RESOLVED_DEST ($label)"
    done
    MODS_DRY_RUN=0

    local wipe="" entry
    while IFS= read -r -d '' entry; do
        [ "$(basename "$entry")" = "lovely" ] && continue
        wipe="${wipe:+$wipe, }$(basename "$entry")"
    done < <(find "$mods_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    echo "wipe:     ${wipe:-<nothing>}"
    echo "preserve: lovely/"

    local pending
    pending="$(mods_pending_get)"
    if [ -n "$pending" ]; then
        echo "backup:   reuse pending $pending"
    else
        echo "backup:   would create $MODS_SNAPSHOT_DIR/<timestamp>/ (Mods entries + save config/)"
    fi
    return "$rc"
}
