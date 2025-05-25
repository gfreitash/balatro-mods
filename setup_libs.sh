#!/bin/bash
set -e

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists curl; then
    echo "Error: curl is not installed. Please install curl and try again."
    exit 1
fi

if ! command_exists unzip; then
    echo "Error: unzip is not installed. Please install unzip and try again."
    exit 1
fi

echo "Starting library setup..."

LIB_DIR="lib"
mkdir -p "$LIB_DIR"
echo "Created directory: $LIB_DIR (if it didn't exist)"

echo ""
echo "Setting up Balatro..."
BALATRO_TARGET_DIR="$LIB_DIR/balatro"
DEFAULT_BALATRO_EXE_PATH="$HOME/.local/share/Steam/steamapps/common/Balatro/Balatro.exe"
ACTUAL_BALATRO_EXE_PATH=""

if [ -f "$DEFAULT_BALATRO_EXE_PATH" ]; then
    echo "Found Balatro.exe at default location: $DEFAULT_BALATRO_EXE_PATH"
    ACTUAL_BALATRO_EXE_PATH="$DEFAULT_BALATRO_EXE_PATH"
else
    echo "Balatro.exe not found at default location ($DEFAULT_BALATRO_EXE_PATH)."
    read -p "Please provide the full path to Balatro.exe: " USER_BALATRO_EXE_PATH
    if [ -f "$USER_BALATRO_EXE_PATH" ]; then
        ACTUAL_BALATRO_EXE_PATH="$USER_BALATRO_EXE_PATH"
        echo "Using user-provided path: $ACTUAL_BALATRO_EXE_PATH"
    else
        echo "Error: Invalid path provided or file does not exist: $USER_BALATRO_EXE_PATH"
        exit 1
    fi
fi

mkdir -p "$BALATRO_TARGET_DIR"
echo "Created directory: $BALATRO_TARGET_DIR"
echo "Unzipping Balatro.exe to $BALATRO_TARGET_DIR..."
echo "Extracting with 7z to handle special headers..."
if ! command -v 7z &> /dev/null; then
    echo "Installing 7z..."
    sudo apt-get update && sudo apt-get install -y p7zip-full
fi
7z x -y -o"$BALATRO_TARGET_DIR" "$ACTUAL_BALATRO_EXE_PATH"
echo "Balatro setup complete."

echo ""
echo "Setting up LÖVE2D..."
LOVE2D_URL="https://github.com/LuaCATS/love2d/archive/refs/heads/main.zip"
LOVE2D_TARGET_DIR="$LIB_DIR/love2d"
LOVE2D_ZIP_FILE="$LIB_DIR/love2d_main.zip"
LOVE2D_EXTRACTED_SUBDIR_NAME="love2d-main"

mkdir -p "$LOVE2D_TARGET_DIR"
echo "Created directory: $LOVE2D_TARGET_DIR"
echo "Downloading LÖVE2D from $LOVE2D_URL..."
curl -L "$LOVE2D_URL" -o "$LOVE2D_ZIP_FILE"
echo "Download complete. Unzipping to $LOVE2D_TARGET_DIR..."
unzip -oq "$LOVE2D_ZIP_FILE" -d "$LIB_DIR"

    EXTRACTED_SRC=""  # Track extracted directory for cleanup
    if [ -d "$LIB_DIR/$LOVE2D_EXTRACTED_SUBDIR_NAME" ]; then
        EXTRACTED_SRC="$LIB_DIR/$LOVE2D_EXTRACTED_SUBDIR_NAME"
        echo "Moving contents from $EXTRACTED_SRC to $LOVE2D_TARGET_DIR..."
        rsync -a "$EXTRACTED_SRC/" "$LOVE2D_TARGET_DIR/"
    else
        EXTRACTED_SRC=$(find "$LIB_DIR" -maxdepth 1 -type d -name "love2d-*" -print -quit)
        if [ -n "$EXTRACTED_SRC" ] && [ -d "$EXTRACTED_SRC" ]; then
            echo "Found a similar directory: $EXTRACTED_SRC. Attempting to use it."
            rsync -a "$EXTRACTED_SRC/" "$LOVE2D_TARGET_DIR/"
        else
            echo "Could not find the extracted LÖVE2D directory. Please check $LIB_DIR manually."
        fi
    fi

    if [ -n "$EXTRACTED_SRC" ] && [ -d "$EXTRACTED_SRC" ]; then
        echo "Cleaning up extracted source directory: $EXTRACTED_SRC"
        rm -rf "$EXTRACTED_SRC"
    fi
rm "$LOVE2D_ZIP_FILE"
echo "LÖVE2D setup complete."

echo ""
echo "Setting up SMods..."
SMODS_URL="https://github.com/Steamodded/smods/archive/refs/heads/main.zip"
SMODS_TARGET_DIR="$LIB_DIR/smods"
SMODS_ZIP_FILE="$LIB_DIR/smods_main.zip"
SMODS_EXTRACTED_SUBDIR_NAME="smods-main"

mkdir -p "$SMODS_TARGET_DIR"
echo "Created directory: $SMODS_TARGET_DIR"
echo "Downloading SMods from $SMODS_URL..."
curl -L "$SMODS_URL" -o "$SMODS_ZIP_FILE"
echo "Download complete. Unzipping to $SMODS_TARGET_DIR..."
unzip -oq "$SMODS_ZIP_FILE" -d "$LIB_DIR"

EXTRACTED_SRC=""  # Track extracted directory for cleanup
if [ -d "$LIB_DIR/$SMODS_EXTRACTED_SUBDIR_NAME" ]; then
    EXTRACTED_SRC="$LIB_DIR/$SMODS_EXTRACTED_SUBDIR_NAME"
    echo "Moving contents from $EXTRACTED_SRC to $SMODS_TARGET_DIR..."
    rsync -a "$EXTRACTED_SRC/" "$SMODS_TARGET_DIR/"
else
    EXTRACTED_SRC=$(find "$LIB_DIR" -maxdepth 1 -type d -name "smods-*" -print -quit)
    if [ -n "$EXTRACTED_SRC" ] && [ -d "$EXTRACTED_SRC" ]; then
        echo "Found a similar directory: $EXTRACTED_SRC. Attempting to use it."
        rsync -a "$EXTRACTED_SRC/" "$SMODS_TARGET_DIR/"
    else
        echo "Could not find the extracted SMods directory. Please check $LIB_DIR manually."
    fi
fi

if [ -n "$EXTRACTED_SRC" ] && [ -d "$EXTRACTED_SRC" ]; then
    echo "Cleaning up extracted source directory: $EXTRACTED_SRC"
    rm -rf "$EXTRACTED_SRC"
fi
rm "$SMODS_ZIP_FILE"
echo "SMods setup complete."

echo ""
echo "Setting up SMods Wiki..."
SMODS_WIKI_URL="https://github.com/Steamodded/Wiki/archive/refs/heads/master.zip"
SMODS_WIKI_TARGET_DIR="$LIB_DIR/wikis/smods"
SMODS_WIKI_ZIP_FILE="$LIB_DIR/smods_wiki_master.zip"
SMODS_WIKI_EXTRACTED_SUBDIR_NAME="Wiki-master"

mkdir -p "$SMODS_WIKI_TARGET_DIR"
echo "Created directory: $SMODS_WIKI_TARGET_DIR"
echo "Downloading SMods Wiki from $SMODS_WIKI_URL..."
curl -L "$SMODS_WIKI_URL" -o "$SMODS_WIKI_ZIP_FILE"
echo "Download complete. Unzipping..."
unzip -oq "$SMODS_WIKI_ZIP_FILE" -d "$LIB_DIR"

EXTRACTED_WIKI_SRC=""
if [ -d "$LIB_DIR/$SMODS_WIKI_EXTRACTED_SUBDIR_NAME" ]; then
    EXTRACTED_WIKI_SRC="$LIB_DIR/$SMODS_WIKI_EXTRACTED_SUBDIR_NAME"
    echo "Moving contents from $EXTRACTED_WIKI_SRC to $SMODS_WIKI_TARGET_DIR..."
    rsync -a "$EXTRACTED_WIKI_SRC/" "$SMODS_WIKI_TARGET_DIR/"
else
    EXTRACTED_WIKI_SRC=$(find "$LIB_DIR" -maxdepth 1 -type d -name "Wiki-*" -print -quit)
    if [ -n "$EXTRACTED_WIKI_SRC" ] && [ -d "$EXTRACTED_WIKI_SRC" ]; then
        echo "Found extracted directory: $EXTRACTED_WIKI_SRC"
        rsync -a "$EXTRACTED_WIKI_SRC/" "$SMODS_WIKI_TARGET_DIR/"
    else
        echo "Could not find extracted SMods Wiki directory"
    fi
fi

if [ -n "$EXTRACTED_WIKI_SRC" ] && [ -d "$EXTRACTED_WIKI_SRC" ]; then
    echo "Cleaning up temporary wiki directory: $EXTRACTED_WIKI_SRC"
    rm -rf "$EXTRACTED_WIKI_SRC"
fi
rm "$SMODS_WIKI_ZIP_FILE"
echo "SMods Wiki setup complete."

echo ""
echo "Setting up Lovely Injector README..."
LOVELY_README_URL="https://github.com/ethangreen-dev/lovely-injector/raw/refs/heads/master/README.md"
LOVELY_TARGET_DIR="$LIB_DIR/wikis/lovely-injector"
LOVELY_TARGET_FILE="$LOVELY_TARGET_DIR/README.md"

mkdir -p "$LOVELY_TARGET_DIR"
echo "Downloading Lovely Injector README..."
curl -L "$LOVELY_README_URL" -o "$LOVELY_TARGET_FILE"
echo "Lovely Injector README setup complete."

echo ""
echo "Setting up symbolic link to Balatro Mods folder..."
MODS_TARGET_PATH="$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"
MODS_LINK_NAME="$LIB_DIR/mod_folder"

if [ -d "$MODS_TARGET_PATH" ]; then
    echo "Target Mods folder found: $MODS_TARGET_PATH"

    # Remove existing file/directory/symlink if it exists
    if [ -e "$MODS_LINK_NAME" ]; then
        echo "Removing existing $MODS_LINK_NAME"
        rm -rf "$MODS_LINK_NAME"
    fi

    # Create symbolic link and handle errors
    if ln -s "$MODS_TARGET_PATH" "$MODS_LINK_NAME"; then
        echo "Symbolic link created: $MODS_LINK_NAME -> $MODS_TARGET_PATH"
    else
        echo "Error: Failed to create symbolic link $MODS_LINK_NAME"
        exit 1
    fi
else
    echo "Warning: Balatro Mods folder not found at $MODS_TARGET_PATH."
    echo "Skipping symbolic link creation for $MODS_LINK_NAME."
    echo "Please ensure Balatro has been run at least once to create this folder, or check the path if it's non-standard."
fi

echo ""
echo "Library setup finished successfully!"
echo "Please ensure the extracted contents are directly within $BALATRO_TARGET_DIR, $LOVE2D_TARGET_DIR, and $SMODS_TARGET_DIR respectively."
