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

# Update manifest dependency only
# Usage: update_manifest_dependency <manifest_file> <dependency>
update_manifest_dependency() {
	local manifest_file="$1"
	local dependency="$2"
	local tmp_file="${manifest_file}.$$"

	log_debug "Updating manifest dependency: ${manifest_file} to ${dependency}"

	jq --arg dep "$dependency" '
		if has("dependencies") and (.dependencies | type == "array") then
			.dependencies = (.dependencies | map(select(startswith("riosodu_shared") | not)) + [$dep] | sort)
		else
			.dependencies = [$dep]
		end
	' "$manifest_file" >"$tmp_file" && mv "$tmp_file" "$manifest_file"
}

# Update manifest version only
# Usage: update_manifest_version <manifest_file> <version>
update_manifest_version() {
	local manifest_file="$1"
	local version="$2"
	local tmp_file="${manifest_file}.$$"

	log_debug "Updating manifest version: ${manifest_file} to ${version}"

	jq --arg ver "$version" '.version = $ver' "$manifest_file" >"$tmp_file" &&
		mv "$tmp_file" "$manifest_file"
}

# Get dependency version from manifest
# Usage: get_dependency_version <manifest_file>
# Returns: version string (e.g., "1.0.0") or empty string if not found/parsed
get_dependency_version() {
	local manifest_file="$1"
	local dep_version=""

	if [ ! -f "$manifest_file" ]; then
		log_debug "Manifest file not found: ${manifest_file}"
		echo ""
		return 0
	fi

	# Extract version from "riosodu_shared (>=X.Y.Z)" or "riosodu_shared (X.Y.Z)" etc.
	# jq -r '.dependencies[] | select(startswith("riosodu_shared"))'
	# This extracts the full string, then we parse the version using grep -oP
	dep_string=$(jq -r '.dependencies[]? | select(startswith("riosodu_shared"))' "$manifest_file" || true)

	if [ -n "$dep_string" ]; then
		dep_version=$(echo "$dep_string" | grep -oP '\(\W*\K[0-9]+\.[0-9]+\.[0-9]+(?=\))' || true)
	fi

	if [ -z "$dep_version" ]; then
		log_debug "Could not find or parse riosodu_shared dependency version in ${manifest_file}. Dependency string: '${dep_string}'"
	else
		log_debug "Found riosodu_shared dependency version: ${dep_version} in ${manifest_file}"
	fi
	echo "$dep_version"
}

# Check if version entry exists in changelog
# Usage: version_entry_exists <changelog_file> <version>
# Returns: 0 if exists, 1 if not found
version_entry_exists() {
	local changelog_file="$1"
	local version="$2"
	grep -q "## \[$version\]" "$changelog_file" 2>/dev/null
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

# Check if index.meta.json needs updating
# Usage: needs_index_meta_update <index_meta_file> <target_version> <mod_name>
# Returns: 0 if needs update, 1 if up to date
needs_index_meta_update() {
	local index_meta_file="$1"
	local target_version="$2"
	local mod_name="$3"

	if [ ! -f "$index_meta_file" ]; then
		return 0 # Needs update (file missing)
	fi

	local index_meta_content
	index_meta_content=$(cat "$index_meta_file")

	# Check version field or downloadURL depending on type
	if echo "$index_meta_content" | jq -e 'has("version")' >/dev/null; then
		local current_version
		current_version=$(echo "$index_meta_content" | jq -r '.version')
		[ "$current_version" != "$target_version" ]
	else
		# For automatic-version-check, validate URL format
		local current_url expected_url repo_path
		current_url=$(echo "$index_meta_content" | jq -r '.downloadURL')
		repo_path=$(git config --get remote.origin.url | sed -E 's/.*github.com[\/:](.*)\.git$/\1/' || true)
		expected_url="https://github.com/${repo_path}/releases/download/${mod_name}__latest/${mod_name}.zip"
		[ "$current_url" != "$expected_url" ]
	fi
}

# Update index.meta.json with version and download URL
# Usage: update_index_meta_json <index_meta_file> <version> <mod_name>
update_index_meta_json() {
	local index_meta_file="$1"
	local version="$2"
	local mod_name="$3"
	local tmp_file="${index_meta_file}.$$"

	log_debug "Updating index.meta.json: ${index_meta_file} for version ${version}"

	local repo_path
	repo_path=$(git config --get remote.origin.url | sed -E 's/.*github.com[\/:](.*)\.git$/\1/' || true)
	if [ -z "$repo_path" ]; then
		log_error "Could not determine GitHub repository path. Please ensure git remote.origin.url is a GitHub URL."
		return 1
	fi

	local index_meta_content
	index_meta_content=$(cat "$index_meta_file")

	# Update based on field type
	if echo "$index_meta_content" | jq -e 'has("version")' >/dev/null; then
		log_debug "Updating 'version' and 'downloadURL' in ${index_meta_file}."
		jq --arg ver "$version" \
			--arg mod_name "$mod_name" \
			--arg repo_path "$repo_path" \
			'.version = $ver | .downloadURL = ("https://github.com/" + $repo_path + "/releases/download/" + $mod_name + "__v" + $ver + "/" + $mod_name + ".zip")' \
			"$index_meta_file" >"$tmp_file" && mv "$tmp_file" "$index_meta_file"
	elif echo "$index_meta_content" | jq -e 'has("automatic-version-check")' >/dev/null; then
		local current_download_url expected_latest_url
		current_download_url=$(echo "$index_meta_content" | jq -r '.downloadURL')
		expected_latest_url="https://github.com/${repo_path}/releases/download/${mod_name}__latest/${mod_name}.zip"

		if [[ "$current_download_url" != "$expected_latest_url" ]]; then
			log_error "Error: Download url is not in the proper format for automatic version updates. It should be '${expected_latest_url}' for ${index_meta_file}."
			return 1
		fi
		# No update needed for automatic-version-check if URL is correct
	fi
}

# --- Phase 1: Pre-flight Validation ---
log_info "Phase 1: Validating repository state..."

VALIDATION_FAILED=false

# MOD_DIRS should contain all mod directories to validate all of them.
MOD_DIRS=$(
	find . -maxdepth 2 -name "manifest.json" ! -path "./_common/*" ! -path "./lib/*" -exec dirname {} \;
)

for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	changelog_file="$mod_dir/CHANGELOG.md"
	manifest_file="$mod_dir/manifest.json"
	index_meta_file="$mod_dir/index.meta.json"

	# If manifest doesn't exist fail validation
	if [ ! -f "$manifest_file" ]; then
		log_error "Manifest file not found for mod '${mod_name}'."
		VALIDATION_FAILED=true
	fi

	# If index.meta.json doesn't exist fail validation
	if [ ! -f "$index_meta_file" ]; then
		log_error "index.meta.json file not found for mod '${mod_name}'."
		VALIDATION_FAILED=true
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
common_manifest="_common/common.json"
SHARED_VERSION=""
SHARED_DEP_REQ=""

if [ -f "$common_changelog" ]; then
	get_latest_version_info "$common_changelog"
	if [ -z "$LATEST_VERSION" ]; then
		log_warn "Could not find a versioned entry in '$common_changelog'. Cannot sync _common and dependencies."
		exit 1
	fi

	SHARED_VERSION=$LATEST_VERSION
	SHARED_DEP_REQ="riosodu_shared (>= ${SHARED_VERSION})"

	current_common_version=$(jq -r '.version' "$common_manifest")
	if [ "$current_common_version" != "$LATEST_VERSION" ]; then
		log_info "Syncing _common: changelog version is '$LATEST_VERSION', manifest is '$current_common_version'."
		jq --arg ver "$LATEST_VERSION" '.version = $ver' "$common_manifest" >"${common_manifest}.$$" &&
			mv "${common_manifest}.$$" "$common_manifest"
		log_success "Updated $common_manifest to version $LATEST_VERSION."
	else
		log_info "_common manifest version is already up to date ($LATEST_VERSION)."
	fi
else
	log_info "No _common changelog found. Skipping _common synchronization."
fi

log_success "Phase 2: Common library sync complete. Canonical version: ${SHARED_VERSION}"

# --- Phase 3: Mod Discovery & Planning ---
log_info "Phase 3: Analyzing mod dependencies and generating update plan..."

UPDATE_PLAN_FILE="/tmp/sync_plan_$$.json"
UPDATE_PLAN='{"shared_version":"'$SHARED_VERSION'","mods":[]}'

for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	manifest_file="$mod_dir/manifest.json"
	changelog_file="$mod_dir/CHANGELOG.md"

	if [ ! -f "$changelog_file" ]; then continue; fi

	log_debug "Analyzing mod: ${mod_name}"

	get_latest_version_info "$changelog_file"
	if [ -z "$LATEST_VERSION" ] || [ -z "$LATEST_VERSION_LINE_NUM" ]; then
		log_warn "Could not find a valid versioned entry in '$changelog_file'. Skipping '$mod_name'."
		continue
	fi

	# Read current state
	mod_manifest_version=$(jq -r '.version' "$manifest_file")
	current_mod_common_dep_version=$(get_dependency_version "$manifest_file")

	# Determine what needs to be done
	needs_changelog=false
	needs_manifest=false
	action="sync_only"
	target_version="$LATEST_VERSION"

	# Check if dependency needs updating
	dependency_needs_update=false
	if [ -z "$current_mod_common_dep_version" ] || \
		{ [ "$(printf '%s\n%s\n' "$current_mod_common_dep_version" "$SHARED_VERSION" | sort -V | head -n 1)" = "$current_mod_common_dep_version" ] && \
		[ "$current_mod_common_dep_version" != "$SHARED_VERSION" ]; }; then
		dependency_needs_update=true
	fi

	# Determine action based on current state
	if [ "$dependency_needs_update" = "true" ]; then
		needs_manifest=true

		# Get version block boundaries for note checking
		BLOCK_END_LINE=$(get_version_block_end "$changelog_file" "$LATEST_VERSION_LINE_NUM")
		update_note="- Updated Riosodu Commons to v${SHARED_VERSION}."
		note_exists="false"
		if note_exists_in_version "$changelog_file" "$LATEST_VERSION" "$update_note"; then
			note_exists="true"
		fi

		if [ "$mod_manifest_version" != "$LATEST_VERSION" ]; then
			# Mod was manually updated, add note to existing version
			if [ "$note_exists" = "false" ]; then
				action="add_note"
				needs_changelog=true
			fi
		else
			# Mod is in sync, need to bump version and create new entry
			if [ "$note_exists" = "false" ]; then
				target_version=$(bump_patch_version "$LATEST_VERSION")
				action="new_entry"
				needs_changelog=true
			fi
		fi
	else
		# Check if manifest version needs syncing (without dependency changes)
		if [ "$mod_manifest_version" != "$LATEST_VERSION" ]; then
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

	manifest_file="$mod_name/manifest.json"
	changelog_file="$mod_name/CHANGELOG.md"
	index_meta_file="$mod_name/index.meta.json"

	# Generate update note dynamically when needed
	update_note="- Updated Riosodu Commons to v${SHARED_VERSION}."

	# Step 1: Update manifest dependency if needed (idempotent)
	if [ "$needs_manifest" = "true" ]; then
		current_dep_version=$(get_dependency_version "$manifest_file")
		if [ "$current_dep_version" != "$SHARED_VERSION" ]; then
			log_info "Updating dependency: $current_dep_version → $SHARED_VERSION"
			update_manifest_dependency "$manifest_file" "$SHARED_DEP_REQ"
			log_success "Updated dependency in $manifest_file"
		else
			log_info "Dependency already correct: $SHARED_VERSION ✓"
		fi
	fi

	# Step 2: Update changelog if needed (idempotent)
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

	# Step 3: Update manifest version (idempotent)
	if [ "$needs_manifest" = "true" ]; then
		current_manifest_version=$(jq -r '.version' "$manifest_file")
		if [ "$current_manifest_version" != "$target_version" ]; then
			log_info "Updating manifest version: $current_manifest_version → $target_version"
			update_manifest_version "$manifest_file" "$target_version"
			log_success "Updated version in $manifest_file"
		else
			log_info "Manifest version already correct: $target_version ✓"
		fi
	fi

	# Step 4: Update index.meta.json (idempotent)
	if needs_index_meta_update "$index_meta_file" "$target_version" "$mod_name"; then
		log_info "Updating index.meta.json for version $target_version"
		update_index_meta_json "$index_meta_file" "$target_version" "$mod_name"
		log_success "Updated $index_meta_file"
	else
		log_info "index.meta.json already up to date ✓"
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
