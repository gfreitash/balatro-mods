#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Helpers ---
C_BLUE='\033[0;34m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_NC='\033[0m'
log_info() { echo -e "${C_BLUE}INFO: $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}SUCCESS: $1${C_NC}"; }
log_warn() { echo -e "${C_YELLOW}WARN: $1${C_NC}"; }
log_error() { echo -e "${C_RED}ERROR: $1${C_NC}"; }
log_debug() {
	# Only print debug messages if DEBUG_MODE is 'true'
	if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
		echo -e "${C_BLUE}DEBUG: $1${C_NC}" >&2
	fi
}

# Enable debug mode for verbose output
# DEBUG_MODE="true"

# --- Prerequisite Check ---
command -v jq >/dev/null 2>&1 || {
	log_error "jq is not installed."
	exit 1
}
command -v git >/dev/null 2>&1 || {
	log_error "git is not installed."
	exit 1
}
command -v file >/dev/null 2>&1 || {
	log_error "file is not installed."
	exit 1
}

# --- Helper Functions ---

# Find line number of a pattern in a file
# Usage: find_line_number <file> <pattern>
# Returns: line number or empty string if not found
find_line_number() {
	local file="$1"
	local pattern="$2"

	# Ensure pattern is not empty to avoid grep errors
	if [ -z "$pattern" ]; then
		log_debug "find_line_number called with empty pattern."
		return 1
	fi

	grep -n -m 1 "$pattern" "$file" 2>/dev/null | cut -d: -f1 || true
}

# Get the latest version string and its line number from changelog
# Usage: get_latest_version_info <changelog_file>
# Sets global variables: LATEST_VERSION, LATEST_VERSION_LINE_NUM
get_latest_version_info() {
	local changelog_file="$1"
	local version_line_info

	version_line_info=$(
		grep -m 1 -n -E "## \[[0-9]+\.[0-9]+\.[0-9]+\]" "$changelog_file" 2>/dev/null ||
			true
	)

	if [ -n "$version_line_info" ]; then
		LATEST_VERSION_LINE_NUM=$(echo "$version_line_info" | cut -d: -f1)
		LATEST_VERSION=$(
			echo "$version_line_info" | grep -oP '\[\K[0-9]+\.[0-9]+\.[0-9]+(?=\])' 2>/dev/null ||
				true
		)
		log_debug "Found latest version: ${LATEST_VERSION} at line ${LATEST_VERSION_LINE_NUM} in ${changelog_file}"
	else
		LATEST_VERSION_LINE_NUM=""
		LATEST_VERSION=""
		log_debug "Could not find latest version in ${changelog_file}"
	fi
}

# Get the end line number of a version block (exclusive - points to next header or EOF+1)
# Usage: get_version_block_end <changelog_file> <start_line_num>
# Returns: end line number (exclusive)
get_version_block_end() {
	local changelog_file="$1"
	local start_line_num="$2"
	local next_header_line_num
	local calculated_end_line

	# Find the next header after start_line_num
	next_header_line_num=$(
		tail -n +"$((start_line_num + 1))" "$changelog_file" 2>/dev/null |
			grep -m 1 -n -E "^## \[" 2>/dev/null |
			cut -d: -f1 || echo ""
	)

	if [ -n "$next_header_line_num" ]; then
		# The end is the line just before the next header (absolute line number)
		calculated_end_line=$((start_line_num + next_header_line_num - 1))
		log_debug "Next header found at relative line ${next_header_line_num}, calculated block end: ${calculated_end_line}"
	else
		# No next header found, block goes to end of file + 1 (for exclusive range)
		calculated_end_line=$(($(wc -l <"$changelog_file") + 1))
		log_debug "No next header found, block extends to end of file + 1: ${calculated_end_line}"
	fi
	echo "${calculated_end_line}"
}

# Check if content exists within a specific line range of a file
# Usage: content_exists_in_range <file> <start_line> <end_line_exclusive> <content>
# Returns: "true" or "false"
content_exists_in_range() {
	local file="$1"
	local start_line="$2"
	local end_line_exclusive="$3" # This is the line number *after* the last line of the block
	local content="$4"
	local actual_end_line

	log_debug "Checking for content: '${content}' in file: '${file}' from line ${start_line} to ${end_line_exclusive} (exclusive)."

	if [ -z "$start_line" ] || [ -z "$end_line_exclusive" ] ||
		[ "$start_line" -ge "$end_line_exclusive" ]; then
		log_debug "Invalid range for content_exists_in_range: start=${start_line}, end=${end_line_exclusive}. Returning false."
		echo "false"
		return
	fi

	# sed range is inclusive, so we need to go up to one line before the exclusive end
	actual_end_line=$((end_line_exclusive - 1))
	log_debug "Sed range will be: ${start_line},${actual_end_line}p"

	local extracted_content
	# Use 'tr -d '\r'' to remove any Windows-style carriage returns which can break grep -F
	extracted_content=$(
		sed -n "${start_line},${actual_end_line}p" "$file" 2>/dev/null |
			tr -d '\r'
	)

	log_debug "Content extracted from range (after \\r removal):\n'${extracted_content}'"
	log_debug "Searching for literal string: '${content}'"

	# Use 'printf %s' to ensure $extracted_content doesn't have trailing newlines added by echo for grep
	# `grep -F -- "$content"`: `--` prevents misinterpretation of pattern if it starts with `-`
	if printf '%s' "$extracted_content" | grep -q -F -- "$content" 2>/dev/null; then
		log_debug "Content '${content}' FOUND in range."
		echo "true"
	else
		log_debug "Content '${content}' NOT FOUND in range."
		echo "false"
	fi
}

# Insert content after a specific line using awk
# Usage: insert_content_after_line <file> <line_number> <content>
insert_content_after_line() {
	local file="$1"
	local target_line="$2"
	local content="$3" # Expects content to already have desired newlines
	local tmp_file="${file}.$$"

	log_debug "Inserting content after line ${target_line} in ${file}:\n'${content}'"

	awk -v target_line="${target_line}" -v content="${content}" '
        { print }
        NR == target_line { print content }
    ' "$file" >"$tmp_file" && mv "$tmp_file" "$file"
}

# Bump patch version (x.y.z -> x.y.z+1)
# Usage: bump_patch_version <version_string>
# Returns: new version string
bump_patch_version() {
	local version="$1"
	local major minor patch new_version

	major=$(echo "$version" | cut -d. -f1)
	minor=$(echo "$version" | cut -d. -f2)
	patch=$(echo "$version" | cut -d. -f3)

	new_version="${major}.${minor}.$((patch + 1))"
	log_debug "Bumped version from ${version} to ${new_version}"
	echo "${new_version}"
}

# Add shared library update note to existing version block
# Usage: add_note_to_existing_version <changelog_file> <version_line_num> <block_end_line_exclusive> <update_note>
add_note_to_existing_version() {
	local changelog_file="$1"
	local version_line_num="$2"
	local block_end_line_exclusive="$3"
	local update_note="$4"
	local changed_section_line_info changed_section_abs_line_num

	log_debug "Attempting to add note to existing version block (lines ${version_line_num} to ${block_end_line_exclusive} exclusive)."

	# Look for existing '### Changed' section within the version block
	local sed_end_line=$((block_end_line_exclusive - 1))
	log_debug "Searching for '### Changed' within sed range: ${version_line_num},${sed_end_line}p"

	changed_section_line_info=$(
		sed -n "${version_line_num},${sed_end_line}p" "$changelog_file" 2>/dev/null |
			grep -n -m 1 "### Changed" 2>/dev/null |
			cut -d: -f1 || true
	)

	if [ -n "$changed_section_line_info" ]; then
		# '### Changed' exists, add note after it
		# Convert relative line info from sed output to absolute line number in file
		changed_section_abs_line_num=$((version_line_num + changed_section_line_info - 1))
		log_debug "'### Changed' found at absolute line: ${changed_section_abs_line_num}. Inserting note after it."
		# Pass the note directly. awk's 'print' will add the necessary newline.
		insert_content_after_line "$changelog_file" "$changed_section_abs_line_num" "$update_note"
		log_success "Added shared lib note under existing '### Changed' section."
	else
		# '### Changed' doesn't exist, create it with the note
		local new_changed_section
		new_changed_section=$(printf '\n### Changed\n%s\n' "$update_note") # Extra newline for proper spacing
		log_debug "No '### Changed' section found. Inserting new section after version header (line ${version_line_num})."
		insert_content_after_line "$changelog_file" "$version_line_num" "$new_changed_section"
		log_success "Created new '### Changed' section with shared lib note."
	fi
}

# Create new version entry in changelog
# Usage: create_new_version_entry <changelog_file> <new_version> <update_note>
create_new_version_entry() {
	local changelog_file="$1"
	local new_version="$2"
	local update_note="$3"
	local unreleased_line_num new_entry_content

	unreleased_line_num=$(find_line_number "$changelog_file" "## \[Unreleased\]")
	if [ -z "$unreleased_line_num" ]; then
		log_error "Could not find '## [Unreleased]' header in '$changelog_file'. Aborting."
		return 1
	fi

	local today
	today=$(date +%Y-%m-%d)
	# Ensure all newlines are embedded correctly for the full block
	new_entry_content=$(
		printf '\n## [%s] - %s\n### Changed\n%s' "$new_version" "$today" "$update_note"
	)

	log_debug "Creating new version entry for ${new_version} and inserting after '## [Unreleased]' (line ${unreleased_line_num})."
	insert_content_after_line "$changelog_file" "$unreleased_line_num" "$new_entry_content"
	log_success "Created new v${new_version} entry in $changelog_file."
}

# Update the version in a Steamodded metadata file (smods.json)
# Usage: update_smods_version <smods_file> <version>
update_smods_version() {
	local smods_file="$1"
	local version="$2"
	local tmp_file="${smods_file}.$$"

	log_debug "Updating smods.json version: ${smods_file} to ${version}"

	jq --arg ver "$version" '.version = $ver' "$smods_file" >"$tmp_file" &&
		mv "$tmp_file" "$smods_file"
}

# Update the version_number in a ThunderStore manifest.json
# Usage: update_ts_manifest_version <manifest_file> <version>
update_ts_manifest_version() {
	local manifest_file="$1"
	local version="$2"
	local tmp_file="${manifest_file}.$$"

	log_debug "Updating ThunderStore manifest version: ${manifest_file} to ${version}"

	jq --arg ver "$version" '.version_number = $ver' "$manifest_file" >"$tmp_file" &&
		mv "$tmp_file" "$manifest_file"
}

# Read the package version from a thunderstore.toml
# Usage: get_toml_version <toml_file>
get_toml_version() {
	local toml_file="$1"
	sed -n 's/^versionNumber[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$toml_file" | head -n 1
}

# Update the versionNumber in a thunderstore.toml
# Usage: update_thunderstore_toml_version <toml_file> <version>
update_thunderstore_toml_version() {
	local toml_file="$1"
	local version="$2"
	local tmp_file="${toml_file}.$$"

	log_debug "Updating thunderstore.toml version: ${toml_file} to ${version}"

	sed -E 's/^(versionNumber[[:space:]]*=[[:space:]]*")[^"]*(".*)$/\1'"$version"'\2/' "$toml_file" >"$tmp_file" &&
		mv "$tmp_file" "$toml_file"
}

# Validate a ThunderStore manifest
# Usage: validate_ts_manifest <manifest_file>
# Returns: 0 if valid, 1 otherwise
validate_ts_manifest() {
	local manifest_file="$1"
	local valid=true

	if ! jq -e '
		has("name") and has("version_number") and has("website_url") and
		has("description") and has("dependencies") and
		(.dependencies | type == "array")
	' "$manifest_file" >/dev/null 2>&1; then
		log_error "Invalid ThunderStore manifest (missing fields): ${manifest_file}"
		return 1
	fi

	local ts_name ts_version ts_desc_len
	ts_name=$(jq -r '.name' "$manifest_file")
	ts_version=$(jq -r '.version_number' "$manifest_file")
	ts_desc_len=$(jq -r '.description | length' "$manifest_file")

	if ! [[ "$ts_name" =~ ^[A-Za-z0-9_]+$ ]]; then
		log_error "Invalid package name '${ts_name}' in ${manifest_file}: only letters, numbers and underscores are allowed."
		valid=false
	fi

	if [ "$ts_desc_len" -gt 250 ]; then
		log_error "Description too long (${ts_desc_len} chars, max 250) in ${manifest_file}."
		valid=false
	fi

	if ! [[ "$ts_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		log_error "Invalid version_number '${ts_version}' in ${manifest_file}: must be Major.Minor.Patch."
		valid=false
	fi

	[ "$valid" = true ]
}

# Check if version entry exists in changelog
# Usage: version_entry_exists <changelog_file> <version>
# Returns: 0 if exists, 1 if not found
version_entry_exists() {
	local changelog_file="$1"
	local version="$2"
	grep -q "## \[$version\]" "$changelog_file" 2>/dev/null
}

# Check if a note exists in ANY versioned block of the changelog.
# Searches only inside `## [x.y.z]` blocks (skips `## [Unreleased]`).
# Usage: note_exists_in_any_versioned_block <changelog_file> <note>
# Returns: 0 if found, 1 if not found
note_exists_in_any_versioned_block() {
	local changelog_file="$1"
	local note="$2"

	# Locate the first `## [x.y.z]` block (skipping `## [Unreleased]`).
	local first_version_line
	first_version_line=$(
		grep -n -m 1 -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" "$changelog_file" 2>/dev/null |
			cut -d: -f1 || true
	)

	if [ -z "$first_version_line" ]; then
		return 1
	fi

	# `grep -F` for a literal-string match; `-q` means quiet.
	tail -n +"$first_version_line" "$changelog_file" 2>/dev/null |
		grep -q -F -- "$note"
}

# Check if specific note exists in version block
# Usage: note_exists_in_version <changelog_file> <version> <note>
# Returns: 0 if exists, 1 if not found
note_exists_in_version() {
	local changelog_file="$1"
	local version="$2"
	local note="$3"

	get_latest_version_info "$changelog_file"
	if [ "$LATEST_VERSION" = "$version" ]; then
		local block_end
		block_end=$(get_version_block_end "$changelog_file" "$LATEST_VERSION_LINE_NUM")
		local result
		result=$(content_exists_in_range "$changelog_file" "$LATEST_VERSION_LINE_NUM" "$block_end" "$note")
		[ "$result" = "true" ]
	else
		return 1
	fi
}

# --- Phase 1: Pre-flight Validation ---
log_info "Phase 1: Validating repository state..."

VALIDATION_FAILED=false

# MOD_DIRS should contain all mod directories to validate all of them.
MOD_DIRS=$(
	find . -maxdepth 2 -name "smods.json" ! -path "./_common/*" ! -path "./lib/*" -exec dirname {} \;
)

for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	changelog_file="$mod_dir/CHANGELOG.md"
	smods_file="$mod_dir/smods.json"
	manifest_file="$mod_dir/manifest.json"
	icon_file="$mod_dir/icon.png"
	readme_file="$mod_dir/README.md"
	toml_file="thunderstore/${mod_name}.toml"

	# Required package metadata files
	for required_file in "$smods_file" "$manifest_file" "$icon_file" "$readme_file" "$toml_file"; do
		if [ ! -f "$required_file" ]; then
			log_error "Required file not found for mod '${mod_name}': ${required_file}"
			VALIDATION_FAILED=true
		fi
	done

	# Validate the ThunderStore manifest fields
	if [ -f "$manifest_file" ] && ! validate_ts_manifest "$manifest_file"; then
		VALIDATION_FAILED=true
	fi

	# Validate the Steamodded metadata is parseable
	if [ -f "$smods_file" ]; then
		if ! jq -e '.version and .id and .main_file' "$smods_file" >/dev/null 2>&1; then
			log_error "Invalid SMods metadata (missing id/version/main_file): ${smods_file}"
			VALIDATION_FAILED=true
		fi
	fi

	# Validate the icon is exactly 256x256
	if [ -f "$icon_file" ]; then
		icon_dims=$(file -b "$icon_file" | grep -oE '[0-9]+ x [0-9]+' | head -n 1 || true)
		if [ "$icon_dims" != "256 x 256" ]; then
			log_error "Icon must be exactly 256x256: ${icon_file} (found: ${icon_dims:-unknown})"
			VALIDATION_FAILED=true
		fi
	fi

	# Skip if changelog doesn't exist
	if [ ! -f "$changelog_file" ]; then continue; fi

	# Check if the [Unreleased] section has content
	# Use sed to extract lines between "## [Unreleased]" and the next "## [" header.
	# -n suppresses auto-print, '/regex/,/regex/p' prints lines in range.
	unreleased_content=$(
		sed -n '/## \[Unreleased\]/,/^## \[/p' "$changelog_file" |
			grep -v -e '##' -e '^[[:space:]]*$' || true # Remove headers and empty lines
	)

	if [ -n "$unreleased_content" ]; then
		log_error "Mod '${mod_name}' has unversioned changes in its changelog."
		log_error "Please create a new version block (e.g., '## [1.2.3] - YYYY-MM-DD') and move the notes before running this script."
		VALIDATION_FAILED=true
	fi
done

if [ "$VALIDATION_FAILED" = true ]; then
	exit 1
fi
log_success "Phase 1: Validation passed. All mods have versioned changelogs."

# --- Phase 2: Common Library Sync ---
log_info "Phase 2: Synchronizing shared library (_common)..."

common_changelog="_common/CHANGELOG.md"
common_version_file="_common/version.lua"
SHARED_VERSION=""

if [ -f "$common_changelog" ]; then
	get_latest_version_info "$common_changelog"
	if [ -z "$LATEST_VERSION" ]; then
		log_warn "Could not find a versioned entry in '$common_changelog'. Cannot sync _common and dependent mods."
		exit 1
	fi

	SHARED_VERSION=$LATEST_VERSION

	# Read the hardcoded version from version.lua (expected format: return "x.y.z")
	current_common_version=$(sed -n 's/^return[[:space:]]*"\([0-9][0-9.]*\)"[[:space:]]*$/\1/p' "$common_version_file" | head -n 1)
	if [ -z "$current_common_version" ]; then
		log_error "Could not parse version from '$common_version_file'. Expected format: return \"x.y.z\"."
		exit 1
	fi

	if [ "$current_common_version" != "$LATEST_VERSION" ]; then
		log_info "Syncing _common: changelog version is '$LATEST_VERSION', version.lua is '$current_common_version'."
		printf 'return "%s"\n' "$LATEST_VERSION" > "$common_version_file"
		log_success "Updated $common_version_file to version $LATEST_VERSION."
	else
		log_info "_common version.lua is already up to date ($LATEST_VERSION)."
	fi
else
	log_info "No _common changelog found. Skipping _common synchronization."
fi

log_success "Phase 2: Common library sync complete. Canonical version: ${SHARED_VERSION}"

# --- Phase 3: Mod Discovery & Planning ---
log_info "Phase 3: Analyzing mods and generating update plan..."

UPDATE_PLAN_FILE="/tmp/sync_plan_$$.json"
UPDATE_PLAN='{"shared_version":"'$SHARED_VERSION'","mods":[]}'

for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	smods_file="$mod_dir/smods.json"
	manifest_file="$mod_dir/manifest.json"
	toml_file="thunderstore/${mod_name}.toml"
	changelog_file="$mod_dir/CHANGELOG.md"

	if [ ! -f "$changelog_file" ]; then continue; fi

	log_debug "Analyzing mod: ${mod_name}"

	get_latest_version_info "$changelog_file"
	if [ -z "$LATEST_VERSION" ] || [ -z "$LATEST_VERSION_LINE_NUM" ]; then
		log_warn "Could not find a valid versioned entry in '$changelog_file'. Skipping '$mod_name'."
		continue
	fi

	# Read current state (smods.json is the canonical Steamodded version)
	mod_manifest_version=$(jq -r '.version' "$smods_file")

	# All metadata files must carry the changelog version
	metadata_in_sync=true
	[ "$mod_manifest_version" = "$LATEST_VERSION" ] || metadata_in_sync=false
	[ "$(jq -r '.version_number' "$manifest_file" 2>/dev/null || echo "")" = "$LATEST_VERSION" ] || metadata_in_sync=false
	[ "$(get_toml_version "$toml_file")" = "$LATEST_VERSION" ] || metadata_in_sync=false

	# Determine what needs to be done
	needs_changelog=false
	needs_manifest=false
	action="sync_only"
	target_version="$LATEST_VERSION"

	# The common library is embedded in each mod, so a mod needs a bump when no
	# version block in its changelog mentions the current Riosodu Commons version.
	# (Searches all versioned blocks, ignoring `## [Unreleased]` so that pending
	# notes don't falsely satisfy this check.)
	update_note="- Updated Riosodu Commons to v${SHARED_VERSION}."
	common_note_present="false"
	if note_exists_in_any_versioned_block "$changelog_file" "$update_note"; then
		common_note_present="true"
	fi

	# Determine action based on current state
	if [ "$common_note_present" = "false" ]; then
		needs_manifest=true

		if [ "$mod_manifest_version" != "$LATEST_VERSION" ]; then
			# Mod was manually updated, add note to existing version
			action="add_note"
			needs_changelog=true
		else
			# Mod is in sync, need to bump version and create new entry
			target_version=$(bump_patch_version "$LATEST_VERSION")
			action="new_entry"
			needs_changelog=true
		fi
	else
		# Sync metadata versions if any file drifted from the changelog
		if [ "$metadata_in_sync" = "false" ]; then
			needs_manifest=true
		fi
	fi

	# Add to plan
	mod_entry=$(jq -n \
		--arg name "$mod_name" \
		--arg current_version "$mod_manifest_version" \
		--arg target_version "$target_version" \
		--arg action "$action" \
		--argjson needs_changelog "$needs_changelog" \
		--argjson needs_manifest "$needs_manifest" \
		'{
			name: $name,
			current_version: $current_version,
			target_version: $target_version,
			action: $action,
			needs_changelog: $needs_changelog,
			needs_manifest: $needs_manifest
		}')

	UPDATE_PLAN=$(echo "$UPDATE_PLAN" | jq --argjson mod "$mod_entry" '.mods += [$mod]')

	log_debug "Mod ${mod_name}: action=${action}, target=${target_version}, changelog=${needs_changelog}, manifest=${needs_manifest}"
done

# Save plan to temp file
echo "$UPDATE_PLAN" >"$UPDATE_PLAN_FILE"

# Display plan summary
mods_needing_updates=$(echo "$UPDATE_PLAN" | jq -r '.mods[] | select(.needs_changelog == true or .needs_manifest == true) | .name' | wc -l)
log_success "Phase 3: Discovery complete. ${mods_needing_updates} mods need updates."

if [ "$mods_needing_updates" -eq 0 ]; then
	log_success "All mods are up to date. Nothing to do."
	rm -f "$UPDATE_PLAN_FILE"
	exit 0
fi

log_info "Update plan generated. Use DEBUG_MODE=true to see detailed plan."
if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
	echo "$UPDATE_PLAN" | jq .
fi

# --- Phase 4: Mod Updates ---
log_info "Phase 4: Executing mod updates..."

# Process each mod that needs updates
echo "$UPDATE_PLAN" | jq -r '.mods[] | select(.needs_changelog == true or .needs_manifest == true) | .name' | while read -r mod_name; do
	echo -e "\n--- Processing Mod: ${C_YELLOW}${mod_name}${C_NC} ---"

	# Extract mod info from plan
	mod_info=$(echo "$UPDATE_PLAN" | jq --arg mod "$mod_name" '.mods[] | select(.name == $mod)')
	target_version=$(echo "$mod_info" | jq -r '.target_version')
	action=$(echo "$mod_info" | jq -r '.action')
	needs_changelog=$(echo "$mod_info" | jq -r '.needs_changelog')
	needs_manifest=$(echo "$mod_info" | jq -r '.needs_manifest')

	smods_file="$mod_name/smods.json"
	manifest_file="$mod_name/manifest.json"
	toml_file="thunderstore/${mod_name}.toml"
	changelog_file="$mod_name/CHANGELOG.md"

	# Generate update note dynamically when needed
	update_note="- Updated Riosodu Commons to v${SHARED_VERSION}."

	# Step 1: Update changelog if needed (idempotent)
	if [ "$needs_changelog" = "true" ]; then
		case "$action" in
		"new_entry")
			if ! version_entry_exists "$changelog_file" "$target_version"; then
				log_info "Creating new changelog entry for $target_version"
				create_new_version_entry "$changelog_file" "$target_version" "$update_note"
			else
				log_info "Changelog entry for $target_version already exists ✓"
			fi
			;;
		"add_note")
			get_latest_version_info "$changelog_file"
			if ! note_exists_in_version "$changelog_file" "$LATEST_VERSION" "$update_note"; then
				log_info "Adding note to existing version $LATEST_VERSION"
				BLOCK_END_LINE=$(get_version_block_end "$changelog_file" "$LATEST_VERSION_LINE_NUM")
				add_note_to_existing_version "$changelog_file" "$LATEST_VERSION_LINE_NUM" "$BLOCK_END_LINE" "$update_note"
			else
				log_info "Note already exists in version $LATEST_VERSION ✓"
			fi
			;;
		esac
	fi

	# Step 2: Update metadata versions (idempotent)
	if [ "$needs_manifest" = "true" ]; then
		current_smods_version=$(jq -r '.version' "$smods_file")
		current_ts_version=$(jq -r '.version_number' "$manifest_file")
		current_toml_version=$(get_toml_version "$toml_file")
		if [ "$current_smods_version" != "$target_version" ] ||
			[ "$current_ts_version" != "$target_version" ] ||
			[ "$current_toml_version" != "$target_version" ]; then
			log_info "Updating metadata versions: smods ${current_smods_version}, thunderstore ${current_ts_version}, toml ${current_toml_version} → ${target_version}"
			update_smods_version "$smods_file" "$target_version"
			update_ts_manifest_version "$manifest_file" "$target_version"
			update_thunderstore_toml_version "$toml_file" "$target_version"
			log_success "Updated $smods_file, $manifest_file and $toml_file"
		else
			log_info "Metadata versions already correct: $target_version ✓"
		fi
	fi

	log_success "Completed processing for mod '$mod_name'"
done

# Cleanup
rm -f "$UPDATE_PLAN_FILE"

echo -e "\n--------------------------------------------------"
log_success "Phase 4: All mod updates complete."
log_success "Version sync complete."
log_info "Review the changes with 'git status' and 'git diff'."
log_info "When ready, stage and commit all changes: 'git add .' -> 'git commit'"
