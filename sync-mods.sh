#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info() { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_error() { echo -e "${C_RED}ERROR: $1${C_NC}"; }

# --- Prerequisite Check ---
check_prerequisites() {
    if ! command -v rsync >/dev/null 2>&1; then
        log_error "Required tool 'rsync' is not installed. Please install it."
        exit 1
    fi
}

# --- Sync Functions ---

# Finds the correct Balatro Mods directory path
# IMPORTANT: This function only prints the final path to stdout.
# All logging is redirected to stderr (>&2) to avoid polluting the output.
determine_destination() {
    local link_path="./lib/mod_folder"
    local default_mods_path="$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"

    if [ -L "$link_path" ]; then
        log_info "Found symbolic link at '$link_path'." >&2 # Redirect to stderr
        readlink -f "$link_path"
    elif [ -d "$default_mods_path" ]; then
        log_info "Found default mods path." >&2 # Redirect to stderr
        echo "$default_mods_path"
    else
        # Return empty string on failure
        echo ""
    fi
}

# Performs the rsync operation for all mods
sync_all_mods() {
    local dest_path="$1"
    log_info "Syncing mods to: $dest_path"

    # Find all directories containing a manifest.json, excluding _common and lib
    local mod_dirs
    mod_dirs=$(find . -maxdepth 2 -name "manifest.json" ! -path "./_common/*" ! -path "./lib/*" -exec dirname {} \;)

    if [ -z "$mod_dirs" ]; then
        log_warn "No mod directories with a manifest.json found to sync."
        return
    fi

    for dir in $mod_dirs; do
        local mod_name
        mod_name=$(basename "$dir")
        echo -e "  · Syncing ${C_YELLOW}${mod_name}${C_NC}"

        # Sync the mod directory itself
        rsync -a --delete --exclude='*.tmp' "$dir/" "$dest_path/$mod_name/"

        # Sync the common library into the mod's destination folder
        if [ -d "_common" ]; then
            rsync -a --delete "_common/" "$dest_path/$mod_name/common/"
            # Rename common.json to manifest.json for consistency
            if [ -f "$dest_path/$mod_name/common/common.json" ]; then
                mv "$dest_path/$mod_name/common/common.json" "$dest_path/$mod_name/common/manifest.json"
            fi
        fi
    done
}

# --- Main Execution ---
main() {
    check_prerequisites

    local destination
    destination=$(determine_destination)

    if [ -z "$destination" ]; then
        log_error "Could not determine destination Mods folder."
        log_error "Please ensure the symlink at './lib/mod_folder' exists or the default path is available."
        exit 1
    fi

    sync_all_mods "$destination"
    log_success "Sync complete."
}

main "$@"