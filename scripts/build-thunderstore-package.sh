#!/usr/bin/env bash
#
# Builds a ThunderStore-compatible package zip for a mod.
#
# Package layout (zip root):
#   manifest.json          ThunderStore manifest
#   icon.png               256x256 package icon
#   README.md              ThunderStore store page
#   CHANGELOG.md           Changelog (rendered on ThunderStore)
#   smods.json             Steamodded metadata
#   ...mod files...
#   common/                bundled _common shared library
#   lovely/common_*.toml   lovely patches from _common
#
# Usage:
#   scripts/build-thunderstore-package.sh <mod-dir> [output-zip]
#
# Arguments:
#   <mod-dir>     Mod directory relative to the repository root (e.g. qol-bundle).
#   [output-zip]  Output zip path (default: dist/<mod-dir>__v<version>.zip).

set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_NC='\033[0m'
log_info() { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_error() { echo -e "${C_RED}ERROR: $1${C_NC}" >&2; }
fail() {
	log_error "$1"
	exit 1
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Prerequisite Check ---
for tool in jq rsync zip unzip file; do
	command -v "$tool" >/dev/null 2>&1 || fail "Required tool '$tool' is not installed."
done

# --- Argument parsing ---
MOD_INPUT="${1:-}"
OUTPUT="${2:-}"

if [ -z "$MOD_INPUT" ]; then
	fail "Usage: $0 <mod-dir> [output-zip]"
fi

MOD_DIR="$REPO_ROOT/$MOD_INPUT"
[ -d "$MOD_DIR" ] || fail "Mod directory not found: $MOD_DIR"

SMODS_MANIFEST="$MOD_DIR/smods.json"
TS_MANIFEST="$MOD_DIR/manifest.json"
ICON="$MOD_DIR/icon.png"
README="$MOD_DIR/README.md"

for required in "$SMODS_MANIFEST" "$TS_MANIFEST" "$ICON" "$README"; do
	[ -f "$required" ] || fail "Missing required package file: $required"
done

# --- Validate ThunderStore manifest ---
jq -e '
	has("name") and has("version_number") and has("website_url") and
	has("description") and has("dependencies") and
	(.dependencies | type == "array")
' "$TS_MANIFEST" >/dev/null || fail "Invalid ThunderStore manifest (missing fields): $TS_MANIFEST"

TS_NAME=$(jq -r '.name' "$TS_MANIFEST")
TS_VERSION=$(jq -r '.version_number' "$TS_MANIFEST")
TS_DESC_LEN=$(jq -r '.description | length' "$TS_MANIFEST")

[[ "$TS_NAME" =~ ^[A-Za-z0-9_]+$ ]] || fail "Invalid package name '${TS_NAME}': only letters, numbers and underscores are allowed."
[ "$TS_DESC_LEN" -le 250 ] || fail "Description too long (${TS_DESC_LEN} chars, max 250)."
[[ "$TS_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid version_number '${TS_VERSION}': must be Major.Minor.Patch."

SMODS_VERSION=$(jq -r '.version' "$SMODS_MANIFEST")
if [ "$SMODS_VERSION" != "$TS_VERSION" ]; then
	fail "Version mismatch: smods.json is ${SMODS_VERSION} but manifest.json is ${TS_VERSION}. Run ./sync-versions.sh."
fi

# --- Validate icon ---
ICON_DIMS=$(file -b "$ICON" | grep -oE '[0-9]+ x [0-9]+' | head -n 1 || true)
if [ "$ICON_DIMS" != "256 x 256" ]; then
	fail "Icon must be exactly 256x256: $ICON (found: ${ICON_DIMS:-unknown})"
fi

# --- Check shared library ---
[ -d "$REPO_ROOT/_common" ] || fail "Shared library directory not found: $REPO_ROOT/_common"

# --- Stage the package ---
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

log_info "Staging package for '${TS_NAME}' v${TS_VERSION}..."
rsync -a \
	--exclude='.git' \
	--exclude='.DS_Store' \
	--exclude='Thumbs.db' \
	--exclude='*.tmp' \
	"$MOD_DIR/" "$STAGING/"

# Bundle the shared library as common/
mkdir -p "$STAGING/common" "$STAGING/lovely"
rsync -a \
	--exclude='.git' \
	--exclude='.DS_Store' \
	--exclude='Thumbs.db' \
	"$REPO_ROOT/_common/" "$STAGING/common/"

# Copy lovely patches to the mod's lovely directory with common_ prefix
for patch_file in "$REPO_ROOT"/_common/lovely/*.toml; do
	[ -f "$patch_file" ] || continue
	base_name=$(basename "$patch_file")
	cp "$patch_file" "$STAGING/lovely/common_$base_name"
done

# --- Create the zip (flat root) ---
if [ -z "$OUTPUT" ]; then
	mkdir -p "$REPO_ROOT/dist"
	OUTPUT="$REPO_ROOT/dist/$(basename "$MOD_INPUT")__v${TS_VERSION}.zip"
elif [[ "$OUTPUT" != /* ]]; then
	OUTPUT="$REPO_ROOT/$OUTPUT"
fi
mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT"

(
	cd "$STAGING"
	zip -qr "$OUTPUT" ./*
)

# --- Validate the resulting archive ---
ENTRIES=$(unzip -Z1 "$OUTPUT")

for required in manifest.json icon.png README.md smods.json; do
	if ! grep -qx "$required" <<<"$ENTRIES"; then
		fail "Package is missing '${required}' at the zip root: $OUTPUT"
	fi
done

if grep -q '^\./' <<<"$ENTRIES"; then
	fail "Package entries must not be prefixed with './': $OUTPUT"
fi

ZIP_SIZE=$(du -h "$OUTPUT" | cut -f1)
log_success "Built ThunderStore package: $OUTPUT (${ZIP_SIZE})"
