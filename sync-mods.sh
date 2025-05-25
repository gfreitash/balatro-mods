#!/usr/bin/env bash
set -euo pipefail

# Path to project symlink
LINK_PATH=".lib/mod_folder/Mods"

# Determine destination directory
if [ -L "$LINK_PATH" ]; then
  DEST="$(readlink -f "$LINK_PATH")"
elif [ -d "$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods" ]; then
  DEST="$HOME/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods"
else
  echo "Error: Destination Mods folder not found." >&2
  exit 1
fi

echo "Syncing mods to $DEST"

# Sync each mod directory (identified by manifest.json)
for dir in */; do
  if [ -f "${dir}manifest.json" ]; then
    mod_name="$(basename "$dir")"
    echo "  · $mod_name"
    rsync -av --delete "$dir" "$DEST/$mod_name"
    # Copy common library into mod's destination folder
    rsync -av --delete "_common/" "$DEST/$mod_name/common/"
    # Rename common.json to manifest.json for consistency
    mv "$DEST/$mod_name/common/common.json" "$DEST/$mod_name/common/manifest.json"
  fi
done

echo "Sync complete."
