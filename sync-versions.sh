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
		new_changed_section=$(printf '\n### Changed\n%s' "$update_note") # awk's print will add the final newline
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
		printf '\n## [%s] - %s\n\n### Changed\n%s' "$new_version" "$today" "$update_note"
	)

	log_debug "Creating new version entry for ${new_version} and inserting after '## [Unreleased]' (line ${unreleased_line_num})."
	insert_content_after_line "$changelog_file" "$unreleased_line_num" "$new_entry_content"
	log_success "Created new v${new_version} entry in $changelog_file."
}

# Update manifest file with version and optionally dependency
# Usage: update_manifest <manifest_file> <version> [dependency]
update_manifest() {
	local manifest_file="$1"
	local version="$2"
	local dependency="${3:-}"
	local tmp_file="${manifest_file}.$$"

	log_debug "Updating manifest: ${manifest_file} to version ${version}, dependency: ${dependency:-None}"

	if [ -n "$dependency" ]; then
		jq --arg ver "$version" --arg dep "$dependency" '.version = $ver | .dependencies = [$dep]' "$manifest_file" >"$tmp_file"
	else
		jq --arg ver "$version" '.version = $ver' "$manifest_file" >"$tmp_file"
	fi

	mv "$tmp_file" "$manifest_file"
}

# --- Phase 1: Validation ---
log_info "Validating repository state..."

COMMIT_RANGE=${COMMIT_RANGE:-""}
CHANGED_FILES=""

# Detect changed files based on whether COMMIT_RANGE is set.
if [ -z "$COMMIT_RANGE" ]; then
	log_info "Local mode detected. Analyzing staged and unstaged files."
	CHANGED_FILES=$( (git diff --name-only --staged; git diff --name-only) | sort -u)
else
	log_info "CI mode detected. Analyzing commit range: $COMMIT_RANGE"
	CHANGED_FILES=$(git diff --name-only "$COMMIT_RANGE")
fi

VALIDATION_FAILED=false

if [ -z "$CHANGED_FILES" ]; then
	log_info "No relevant changes detected. Nothing to do."
	exit 0
fi

MOD_DIRS=$(
	find . -maxdepth 2 -name "manifest.json" ! -path "./_common/*" ! -path "./lib/*" -exec dirname {} \;
)

for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	changelog_file="$mod_dir/CHANGELOG.md"

	# Check only mods that have been changed
	if echo "$CHANGED_FILES" | grep -q -E "^${mod_name}/"; then
		if [ ! -f "$changelog_file" ]; then continue; fi

		# Check if the [Unreleased] section has content
		unreleased_content=$(
			sed -n '/## \[Unreleased\]/,/^## \[/p' "$changelog_file" |
				grep -v -e '##' -e '^[[:space:]]*$' || true
		)
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

# --- Phase 2a: Sync Shared Library ---
log_info "Synchronizing shared library (_common)..."
COMMON_WAS_CHANGED=false
if echo "$CHANGED_FILES" | grep -q -E "^_common/"; then
	COMMON_WAS_CHANGED=true
	common_changelog="_common/CHANGELOG.md"
	common_manifest="_common/common.json"

	if [ -f "$common_changelog" ]; then
		get_latest_version_info "$common_changelog"
		if [ -n "$LATEST_VERSION" ]; then
			current_common_version=$(jq -r '.version' "$common_manifest")
			if [ "$current_common_version" != "$LATEST_VERSION" ]; then
				log_info "Syncing _common: changelog version is '$LATEST_VERSION', manifest is '$current_common_version'."
				jq --arg ver "$LATEST_VERSION" '.version = $ver' "$common_manifest" >"${common_manifest}.$$" &&
					mv "${common_manifest}.$$" "$common_manifest"
				log_success "Updated $common_manifest to version $LATEST_VERSION."
			else
				log_info "_common manifest version is already up to date ($LATEST_VERSION)."
			fi
			# Set shared variables for use in Phase 2b
			SHARED_VERSION=$LATEST_VERSION
			SHARED_DEP_REQ="riosodu_shared (>=${SHARED_VERSION})"
			log_info "Changes detected in _common/ (v${SHARED_VERSION}). Dependent mods will be updated."
		else
			log_warn "Could not find a versioned entry in '$common_changelog'. Cannot sync _common."
			COMMON_WAS_CHANGED=false # Prevent dependent mods from updating
		fi
	else
		log_warn "No changelog found for _common. Cannot sync."
		COMMON_WAS_CHANGED=false # Prevent dependent mods from updating
	fi
fi

# --- Phase 2b: Sync Individual Mods ---
log_info "Synchronizing individual mod manifests with changelogs..."

for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	manifest_file="$mod_dir/manifest.json"
	changelog_file="$mod_dir/CHANGELOG.md"

	if [ ! -f "$changelog_file" ]; then continue; fi

	# Get latest version info
	get_latest_version_info "$changelog_file"

	if [ -z "$LATEST_VERSION" ] || [ -z "$LATEST_VERSION_LINE_NUM" ]; then
		log_warn "Could not find a valid versioned entry in '$changelog_file'. Skipping sync for '$mod_name'."
		continue
	fi

	# Get version block boundaries
	# BLOCK_END_LINE will be the line number of the *next* header, or EOF+1
	BLOCK_END_LINE=$(get_version_block_end "$changelog_file" "$LATEST_VERSION_LINE_NUM")

	# Check if this mod was changed
	MOD_WAS_CHANGED=false
	if echo "$CHANGED_FILES" | grep -q -E "^${mod_name}/"; then
		MOD_WAS_CHANGED=true
	fi

	# Process shared library changes
	if [ "$COMMON_WAS_CHANGED" = true ]; then
		update_note="- Updated Riosodu Commons to v${SHARED_VERSION}."

		# Check if update note already exists in the latest version block
		note_exists=$(
			content_exists_in_range "$changelog_file" "$LATEST_VERSION_LINE_NUM" "$BLOCK_END_LINE" "$update_note"
		)
		log_info "Checking for shared lib update note in v${LATEST_VERSION} (range ${LATEST_VERSION_LINE_NUM}-${BLOCK_END_LINE} exclusive): ${note_exists}"

		if [ "$MOD_WAS_CHANGED" = true ]; then
			# SCENARIO 1: Mod was changed AND _common was changed
			echo -e "\n--- Processing Mod: ${C_YELLOW}${mod_name}${C_NC} (Mod + Shared Lib Changed) ---"
			if [ "$note_exists" = "true" ]; then
				log_info "Shared lib update note already exists in v${LATEST_VERSION}, skipping injection."
			else
				add_note_to_existing_version "$changelog_file" "$LATEST_VERSION_LINE_NUM" "$BLOCK_END_LINE" "$update_note"
			fi
		else
			# SCENARIO 2: Only _common was changed
			echo -e "\n--- Processing Mod: ${C_YELLOW}${mod_name}${C_NC} (Shared Lib Only Changed) ---"
			if [ "$note_exists" = "true" ]; then
				log_info "Version ${LATEST_VERSION} with shared lib update already exists, skipping version bump."
			else
				new_version=$(bump_patch_version "$LATEST_VERSION")
				log_info "Bumping version from ${LATEST_VERSION} -> ${new_version}"

				create_new_version_entry "$changelog_file" "$new_version" "$update_note"

				# Update latest version for manifest sync
				LATEST_VERSION=$new_version
			fi
		fi
	fi

	# Sync manifest.json version with changelog
	current_manifest_version=$(jq -r '.version' "$manifest_file")

	if [ "$current_manifest_version" != "$LATEST_VERSION" ]; then
		log_info "Syncing manifest.json for '${mod_name}': changelog version is '$LATEST_VERSION', manifest is '$current_manifest_version'."

		if [ "$COMMON_WAS_CHANGED" = true ]; then
			update_manifest "$manifest_file" "$LATEST_VERSION" "$SHARED_DEP_REQ"
		else
			update_manifest "$manifest_file" "$LATEST_VERSION"
		fi
		log_success "Updated $manifest_file to version $LATEST_VERSION."
	elif [ "$COMMON_WAS_CHANGED" = true ]; then
		log_info "Updating dependency info in manifest.json for '${mod_name}'."
		jq --arg dep "$SHARED_DEP_REQ" '.dependencies = [$dep]' "$manifest_file" >"${manifest_file}.$$" &&
			mv "${manifest_file}.$$" "$manifest_file"
		log_success "Updated dependencies in $manifest_file."
	fi

	# --- Sync index.meta.json ---
	index_meta_file="$mod_dir/index.meta.json"
	if [ -f "$index_meta_file" ]; then
		log_info "Processing index.meta.json for '${mod_name}'..."
		tmp_index_meta_file="${index_meta_file}.$$"
		index_meta_content=$(cat "$index_meta_file")

		repo_path=$(git config --get remote.origin.url | sed -E 's/.*github.com[\/:](.*)\.git$/\1/' || true)
		if [ -z "$repo_path" ]; then
			log_error "Could not determine GitHub repository path. Please ensure git remote.origin.url is a GitHub URL."
			VALIDATION_FAILED=true
			continue
		fi
		log_debug "Determined repo_path: ${repo_path}"

		# Strict XOR check: 'version' OR 'automatic-version-check', but not both, and one must be present.
		if ! jq -e '(has("version") and (has("automatic-version-check") | not)) or ((has("version") | not) and has("automatic-version-check"))' <<< "$index_meta_content" >/dev/null; then
			log_error "Error: ${index_meta_file} must have exactly one of 'version' or 'automatic-version-check' fields."
			VALIDATION_FAILED=true
			continue
		fi

		# If 'version' field exists (and 'automatic-version-check' does not, due to XOR)
		if echo "$index_meta_content" | jq -e 'has("version")' >/dev/null; then
			log_info "Updating 'version' and 'downloadURL' in ${index_meta_file}."
			jq --arg ver "$LATEST_VERSION" \
				--arg mod_name "$mod_name" \
				--arg repo_path "$repo_path" \
				'.version = $ver | .downloadURL = ("https://github.com/" + $repo_path + "/releases/download/" + $mod_name + "__v" + $ver + "/" + $mod_name + ".zip")' \
				"$index_meta_file" >"$tmp_index_meta_file" && mv "$tmp_index_meta_file" "$index_meta_file"
			log_success "Updated ${index_meta_file} with version ${LATEST_VERSION} and new downloadURL."
		# If 'automatic-version-check' field exists (and 'version' does not, due to XOR)
		elif echo "$index_meta_content" | jq -e 'has("automatic-version-check")' >/dev/null; then
			current_download_url=$(jq -r '.downloadURL' "$index_meta_file")

			# Construct expected_latest_url using the pre-calculated repo_path
			expected_latest_url="https://github.com/${repo_path}/releases/download/${mod_name}__latest/${mod_name}.zip"
			log_debug "Current downloadURL: ${current_download_url}"
			log_debug "Expected latest downloadURL: ${expected_latest_url}"

			if [[ "$current_download_url" != "$expected_latest_url" ]]; then
				log_error "Error: Download url is not in the proper format for automatic version updates. It should be '${expected_latest_url}' for ${index_meta_file}."
				VALIDATION_FAILED=true
				continue
			fi
		fi
	fi
done

if [ "$VALIDATION_FAILED" = true ]; then
	log_error "One or more index.meta.json files failed validation. Please fix the errors above."
	exit 1
fi

echo -e "\n--------------------------------------------------"
log_success "Version sync complete."
log_info "Review the new changes with 'git status' and 'git diff'."
log_info "When ready, stage and commit all changes: 'git add .' -> 'git commit'"
