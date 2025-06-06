#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log_info() { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn() { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error() { echo -e "${C_RED}ERROR: $1${C_NC}"; }

# --- Prerequisite Check ---
check_prerequisites() {
    log_info "Checking for required tools..."
    local missing_tools=0
    for tool in curl unzip 7z rsync; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "Required tool '$tool' is not installed."
            missing_tools=$((missing_tools + 1))
        fi
    done

    if [ "$missing_tools" -gt 0 ]; then
        log_error "Please install the missing tools and try again."
        exit 1
    fi
    log_success "All required tools are present."
}

# --- Setup Functions ---

# Generic function to download, extract, and clean up a zip-based library
setup_zip_lib() {
    local lib_name="$1"
    local url="$2"
    local target_dir="$3"
    local zip_subdir_name="$4"
    local zip_file="${target_dir}.zip"

    echo ""
    log_info "Setting up ${lib_name}..."
    mkdir -p "$target_dir"
    log_info "Downloading ${lib_name} from ${url}..."
    curl -L "$url" -o "$zip_file"
    log_info "Download complete. Unzipping..."
    unzip -oq "$zip_file" -d "$LIB_DIR"

    local extracted_src="$LIB_DIR/$zip_subdir_name"
    if [ ! -d "$extracted_src" ]; then
        # Fallback for cases where the zip extracts to a different name (e.g., with commit hash)
        extracted_src=$(find "$LIB_DIR" -maxdepth 1 -type d -name "${lib_name,,}-*" -print -quit)
    fi

    if [ -n "$extracted_src" ] && [ -d "$extracted_src" ]; then
        log_info "Moving contents from $extracted_src to $target_dir..."
        rsync -a --remove-source-files "$extracted_src/" "$target_dir/"
        rm -r "$extracted_src"
    else
        log_error "Could not find the extracted ${lib_name} directory. Please check '$LIB_DIR' manually."
        exit 1
    fi

    rm "$zip_file"
    log_success "${lib_name} setup complete."
}

setup_balatro() {
    echo ""
    log_info "Setting up Balatro..."
    local target_dir="$LIB_DIR/balatro"
    local default_exe_path="$HOME/.local/share/Steam/steamapps/common/Balatro/Balatro.exe"
    local actual_exe_path=""

    if [ -f "$default_exe_path" ]; then
        log_info "Found Balatro.exe at default location: $default_exe_path"
        actual_exe_path="$default_exe_path"
    else
        log_warn "Balatro.exe not found at default location."
        read -p "Please provide the full path to Balatro.exe: " user_exe_path
        if [ -f "$user_exe_path" ]; then
            actual_exe_path="$user_exe_path"
            log_info "Using user-provided path: $actual_exe_path"
        else
            log_error "Invalid path provided or file does not exist: $user_exe_path"
            exit 1
        fi
    fi

    mkdir -p "$target_dir"
    log_info "Extracting Balatro.exe to $target_dir with 7z..."
    7z x -y -o"$target_dir" "$actual_exe_path" > /dev/null
    log_success "Balatro setup complete."
}

setup_symlink() {
    echo ""
    log_info "Setting up symbolic link to Balatro Mods folder..."
    local target_path="$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"
    local link_name="$LIB_DIR/mod_folder"

    if [ -d "$target_path" ]; then
        log_info "Target Mods folder found: $target_path"
        if [ -e "$link_name" ]; then
            log_info "Removing existing link/file at $link_name"
            rm -rf "$link_name"
        fi
        ln -s "$target_path" "$link_name"
        log_success "Symbolic link created: $link_name -> $target_path"
    else
        log_warn "Balatro Mods folder not found at $target_path."
        log_warn "Skipping symbolic link creation. Please run Balatro at least once."
    fi
}

# --- Main Execution ---
main() {
    check_prerequisites

    log_info "Starting library setup..."
    LIB_DIR="lib"
    mkdir -p "$LIB_DIR"
    log_success "Created directory: $LIB_DIR (if it didn't exist)"

    setup_balatro

    setup_zip_lib "LÖVE2D" \
        "https://github.com/LuaCATS/love2d/archive/refs/heads/main.zip" \
        "$LIB_DIR/love2d" \
        "love2d-main"

    setup_zip_lib "SMods" \
        "https://github.com/Steamodded/smods/archive/refs/heads/main.zip" \
        "$LIB_DIR/smods" \
        "smods-main"

    setup_zip_lib "SMods Wiki" \
        "https://github.com/Steamodded/Wiki/archive/refs/heads/master.zip" \
        "$LIB_DIR/wikis/smods" \
        "Wiki-master"

    # Lovely Injector README is a single file, so no need for the zip helper
    echo ""
    log_info "Setting up Lovely Injector README..."
    local lovely_target_dir="$LIB_DIR/wikis/lovely-injector"
    mkdir -p "$lovely_target_dir"
    curl -L "https://github.com/ethangreen-dev/lovely-injector/raw/refs/heads/master/README.md" -o "$lovely_target_dir/README.md"
    log_success "Lovely Injector README setup complete."

    setup_symlink

    echo ""
    log_success "Library setup finished successfully!"
}

main "$@"