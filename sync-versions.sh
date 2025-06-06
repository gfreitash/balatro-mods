#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info() { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn() { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error() { echo -e "${C_RED}ERROR: $1${C_NC}"; }

# --- Prerequisite Check ---
command -v jq >/dev/null 2>&1 || { log_error "jq is not installed."; exit 1; }
command -v git >/dev/null 2>&1 || { log_error "git is not installed."; exit 1; }

# --- Phase 1: Validation ---
log_info "Validating repository state..."
CHANGED_FILES=$(git diff --name-only --staged; git diff --name-only)
VALIDATION_FAILED=false

if [ -z "$CHANGED_FILES" ]; then
    log_info "No staged or unstaged changes detected. Nothing to do."
    exit 0
fi

MOD_DIRS=$(find . -maxdepth 2 -name "manifest.json" ! -path "./_common/*" ! -path "./lib/*" -exec dirname {} \;)

for mod_dir in $MOD_DIRS; do
    mod_name=$(basename "$mod_dir")
    changelog_file="$mod_dir/CHANGELOG.md"

    # Check only mods that have been changed
    if echo "$CHANGED_FILES" | grep -q "^${mod_name}/"; then
        if [ ! -f "$changelog_file" ]; then continue; fi

        # Check if the [Unreleased] section has content
        unreleased_content=$(sed -n '/## \[Unreleased\]/,/^## \[/p' "$changelog_file" | grep -v -e '##' -e '^[[:space:]]*$')
        if [ -n "$unreleased_content" ]; then
            log_error "Mod '${mod_name}' has unversioned changes in its changelog."
            log_error "Please create a new version block (e.g., '## [1.2.3] - YYYY-MM-DD') and move the notes before running this script."
            VALIDATION_FAILED=true
        fi
    fi
done

if [ "$VALIDATION_FAILED" = true ]; then
    exit 1
fi
log_success "Validation passed. All changed mods have versioned changelogs."

# --- Phase 2: Synchronization ---
log_info "Synchronizing manifest versions with changelogs..."

COMMON_WAS_CHANGED=false
SHARED_VERSION=""
if echo "$CHANGED_FILES" | grep -q "^_common/"; then
    COMMON_WAS_CHANGED=true
    SHARED_VERSION=$(jq -r '.version' "_common/common.json")
    SHARED_DEP_REQ="riosodu_shared>=${SHARED_VERSION}"
    log_info "Changes detected in _common/ (v${SHARED_VERSION}). Will propagate to dependent mods."
fi

for mod_dir in $MOD_DIRS; do
    mod_name=$(basename "$mod_dir")
    manifest_file="$mod_dir/manifest.json"
    changelog_file="$mod_dir/CHANGELOG.md"
    tmp_file="${manifest_file}.$$}"

    if [ ! -f "$changelog_file" ]; then continue; fi

    # Find the latest versioned entry (e.g., [1.2.3]) in the changelog
    latest_version_line=$(grep -m 1 -E "## \[[0-9]+\.[0-9]+\.[0-9]+\]" "$changelog_file" || true)
    if [ -z "$latest_version_line" ]; then continue; fi
    latest_version=$(echo "$latest_version_line" | grep -oP '\[\K[0-9]+\.[0-9]+\.[0-9]+(?=\])')

    # If _common was changed, inject the update note into the latest version block
    if [ "$COMMON_WAS_CHANGED" = true ]; then
        echo -e "\n--- Processing Mod: ${C_YELLOW}${mod_name}${C_NC} (Injecting Shared Update) ---"
        update_note="- Updated Riosodu Commons to v${SHARED_VERSION}."

        # Get line numbers for the start and end of the latest version block
        start_line=$(grep -n "^## \\[$latest_version\\]" "$changelog_file" | cut -d: -f1)
        end_line=$(grep -n -m 1 "^## \\[" "$changelog_file" | tail -n +2 | head -n 1 | cut -d: -f1)
        end_line=${end_line:-$(wc -l < "$changelog_file")} # Use EOF if no subsequent block

        # Check if '### Changed' exists within this block
        if sed -n "${start_line},${end_line}p" "$changelog_file" | grep -q "### Changed"; then
            # Insert the note under the existing '### Changed'
            sed -i "/^## \\[$latest_version\\]/,/^## \\[/ { /### Changed/a \\
${update_note}
}" "$changelog_file"
            log_success "Added shared lib note under existing '### Changed' section."
        else
            # Add a new '### Changed' section right after the version header
            sed -i "${start_line}a \\\n### Changed\n${update_note}" "$changelog_file"
            log_success "Created new '### Changed' section with shared lib note."
        fi
    fi

    # Sync manifest version with the changelog version
    current_manifest_version=$(jq -r '.version' "$manifest_file")
    if [ "$current_manifest_version" != "$latest_version" ] || [ "$COMMON_WAS_CHANGED" = true ]; then
        echo -e "\n--- Processing Mod: ${C_YELLOW}${mod_name}${C_NC} (Syncing Manifest) ---"
        log_info "Syncing manifest: changelog version is '$latest_version', manifest version is '$current_manifest_version'."

        if [ "$COMMON_WAS_CHANGED" = true ]; then
            jq --arg ver "$latest_version" --arg dep "$SHARED_DEP_REQ" '.version = $ver | .dependencies = [$dep]' "$manifest_file" > "$tmp_file"
        else
            jq --arg ver "$latest_version" '.version = $ver' "$manifest_file" > "$tmp_file"
        fi
        mv "$tmp_file" "$manifest_file"
        log_success "Updated $manifest_file to version $latest_version."
    fi
done

echo -e "\n--------------------------------------------------"
log_success "Version sync complete."
log_info "Review the new changes with 'git status' and 'git diff'."
log_info "When ready, stage and commit all changes: 'git add .' -> 'git commit'"