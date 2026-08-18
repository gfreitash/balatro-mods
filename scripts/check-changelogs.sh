#!/usr/bin/env bash
#
# Validates that for any mod directory with changes in the PR:
#   (A) The mod's CHANGELOG.md has a non-empty `## [Unreleased]` section.
#   (B) No additions/deletions have been made outside that section
#       (i.e. already-released version blocks are immutable).
#
# Usage:
#   ./scripts/check-changelogs.sh <base_ref>
#
# Arguments:
#   <base_ref>  Git ref to diff against (e.g. "origin/main"). Required.
#
# Exits 0 on success, 1 on any violation.

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

# --- Prerequisite Check ---
command -v git >/dev/null 2>&1 || {
	log_error "git is not installed."
	exit 1
}

# --- Argument parsing ---
if [ $# -lt 1 ]; then
	log_error "Usage: $0 <base_ref>"
	log_error "Example: $0 origin/main"
	exit 1
fi
BASE_REF="$1"

if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
	log_error "Base ref '$BASE_REF' is not a valid git ref."
	exit 1
fi

HEAD_SHA=$(git rev-parse --verify HEAD)
log_info "Comparing HEAD ($HEAD_SHA) against base ($BASE_REF)"

# --- Discover changed files ---
CHANGED_FILES=$(git diff --name-only "$BASE_REF"...HEAD 2>/dev/null || true)
if [ -z "$CHANGED_FILES" ]; then
	log_success "No files changed. Nothing to validate."
	exit 0
fi

# --- Discover mod directories (matches sync-versions.sh logic) ---
# Normalize: strip the leading "./" so paths match `git diff --name-only` output
# (which never includes the "./" prefix).
MOD_DIRS=$(
	find . -maxdepth 2 -name "manifest.json" ! -path "./_common/*" ! -path "./lib/*" -exec dirname {} \; |
		sed 's|^\./||'
)

# _common is treated specially (shared library) but uses the same rules.
EXTRA_DIRS="_common"

# Collect violations as we go; print all at the end.
FAILED=false
declare -a FAILURES

record_failure() {
	FAILED=true
	FAILURES+=("$1")
}

# --- Helper Functions ---

# Find the line number (1-indexed) of the first occurrence of a pattern in a file.
# Usage: find_line_number <file> <pattern>
# Echoes the line number, or empty string if not found.
find_line_number() {
	local file="$1"
	local pattern="$2"

	if [ -z "$pattern" ]; then
		return 1
	fi
	grep -n -m 1 "$pattern" "$file" 2>/dev/null | cut -d: -f1 || true
}

# Get the end line number (exclusive — points to next header or EOF+1) of an
# Unreleased block starting at <start_line>.
# Usage: get_unreleased_block_end <file> <start_line>
# Echoes the end line (exclusive).
get_unreleased_block_end() {
	local file="$1"
	local start_line="$2"
	local next_header_rel
	local calculated_end

	next_header_rel=$(
		tail -n +"$((start_line + 1))" "$file" 2>/dev/null |
			grep -m 1 -n -E "^## \[" 2>/dev/null |
			cut -d: -f1 || echo ""
	)

	if [ -n "$next_header_rel" ]; then
		calculated_end=$((start_line + next_header_rel - 1))
	else
		calculated_end=$(($(wc -l <"$file") + 1))
	fi
	echo "${calculated_end}"
}

# Rule A — verify the Unreleased section exists and has at least one bullet.
# Usage: check_unreleased_section <changelog_file>
check_unreleased_section() {
	local file="$1"
	local unreleased_line block_end content

	unreleased_line=$(find_line_number "$file" "## \[Unreleased\]")
	if [ -z "$unreleased_line" ]; then
		log_error "Rule A (Unreleased present): missing '## [Unreleased]' section in ${file}."
		record_failure "Rule A: '${file}' is missing '## [Unreleased]'."
		return
	fi

	block_end=$(get_unreleased_block_end "$file" "$unreleased_line")
	local actual_end=$((block_end - 1))

	# Extract content between the Unreleased header and the next header.
	# Strip Windows-style \r, header lines (### / ##) and blank lines.
	content=$(
		sed -n "${unreleased_line},${actual_end}p" "$file" 2>/dev/null |
			tr -d '\r' |
			grep -v -e '^#' -e '^[[:space:]]*$' || true
	)

	if [ -z "$content" ]; then
		log_error "Rule A (Unreleased non-empty): '## [Unreleased]' in ${file} is empty."
		record_failure "Rule A: '${file}' has an empty '## [Unreleased]' section."
		return
	fi

	log_success "Rule A passed for ${file}"
}

# Rule B — verify no additions or deletions outside the Unreleased section.
# Usage: check_no_changes_outside_unreleased <changelog_file> <base_ref>
check_no_changes_outside_unreleased() {
	local file="$1"
	local base="$2"
	local unreleased_line block_end actual_end

	unreleased_line=$(find_line_number "$file" "## \[Unreleased\]")
	if [ -z "$unreleased_line" ]; then
		# Already reported by Rule A; skip to avoid duplicate noise.
		return
	fi
	block_end=$(get_unreleased_block_end "$file" "$unreleased_line")
	actual_end=$((block_end - 1))

	# Walk the diff of this file between base and HEAD, line by line, tracking
	# the resulting line number in the new file as we go.
	#
	# We use `git diff --unified=0` so each hunk is minimal; for additions we
	# know the new file's line number directly; for deletions we know the base
	# file's line number and can mark it as a deletion in a versioned section.
	local new_line=0
	local old_line=0
	local violations=0

	# Process the diff in order. State machine:
	#   - "@@ -a,b +c,d @@" sets new_line=c, old_line=a (we ignore b/d; we
	#     don't expect large enough diffs here that context length matters).
	#   - lines starting with '+' (not '+++') are additions to the new file at new_line.
	#   - lines starting with '-' (not '---') are deletions from the old file at old_line.
	#   - lines starting with ' ' are context; both counters advance.
	while IFS= read -r line; do
		case "$line" in
		"@@"*)
			# Parse hunk header: "@@ -<old_start>[,<old_len>] +<new_start>[,<new_len>] @@"
			local hunk
			hunk=$(echo "$line" | sed -nE 's/^@@ -[0-9]+(,[0-9]+)? \+([0-9]+)(,[0-9]+)? @@.*/\2/p')
			if [ -n "$hunk" ]; then
				new_line="$hunk"
				old_line=$(echo "$line" | sed -nE 's/^@@ -([0-9]+)(,[0-9]+)? \+[0-9]+(,[0-9]+)? @@.*/\1/p')
			fi
			;;
		"+"*)
			# Skip file headers.
			if [ "${line:0:3}" = "+++" ]; then
				continue
			fi
			local content="${line:1}"
			# Is this new_line within the Unreleased range?
			if [ "$new_line" -lt "$unreleased_line" ] || [ "$new_line" -gt "$actual_end" ]; then
				violations=$((violations + 1))
				log_error "Rule B (history immutable): addition at ${file}:${new_line} outside '## [Unreleased]'."
				log_error "    ${content}"
				record_failure "Rule B: '${file}' line ${new_line} adds content outside '## [Unreleased]'."
			fi
			new_line=$((new_line + 1))
			;;
		"-"*)
			# Skip file headers.
			if [ "${line:0:3}" = "---" ]; then
				continue
			fi
			# Only flag deletions that come from a versioned section
			# (historical entries are immutable). Deletions inside the
			# Unreleased block are allowed — the contributor may legitimately
			# rephrase or remove a pending note.
			if [ "$old_line" -lt "$unreleased_line" ] || [ "$old_line" -gt "$actual_end" ]; then
				violations=$((violations + 1))
				log_error "Rule B (history immutable): deletion at ${file} in old line ${old_line} (versioned section)."
				log_error "    ${line:1}"
				record_failure "Rule B: '${file}' deletes content from a versioned section at old line ${old_line}."
			fi
			old_line=$((old_line + 1))
			;;
		" "*)
			new_line=$((new_line + 1))
			old_line=$((old_line + 1))
			;;
		*)
			# Other lines (e.g. "\ No newline at end of file") — ignore.
			;;
		esac
	done < <(git diff --unified=0 --no-color "$base"...HEAD -- "$file" 2>/dev/null || true)

	if [ "$violations" -eq 0 ]; then
		log_success "Rule B passed for ${file}"
	fi
}

# --- Main validation loop ---
log_info "Validating changelogs for changed mod directories..."

# Process each mod directory.
for mod_dir in $MOD_DIRS; do
	mod_name=$(basename "$mod_dir")
	changelog_file="$mod_dir/CHANGELOG.md"

	# Does this PR touch any file under this mod dir?
	if ! echo "$CHANGED_FILES" | grep -q "^${mod_dir}/"; then
		log_info "Skipping '${mod_name}' — no files changed under ${mod_dir}/"
		continue
	fi

	log_info "Validating '${mod_name}' (${mod_dir}/)..."

	# Rule A prerequisite: a CHANGELOG.md must exist if code is changed.
	if [ ! -f "$changelog_file" ]; then
		log_error "Missing ${changelog_file} for modified mod '${mod_name}'."
		record_failure "Missing '${changelog_file}'. Create one with a '## [Unreleased]' section describing the changes."
		continue
	fi

	check_unreleased_section "$changelog_file"
	check_no_changes_outside_unreleased "$changelog_file" "$BASE_REF"
done

# Process _common/ (shared library) with the same rules.
for extra_dir in $EXTRA_DIRS; do
	changelog_file="$extra_dir/CHANGELOG.md"

	if ! echo "$CHANGED_FILES" | grep -q "^${extra_dir}/"; then
		log_info "Skipping '${extra_dir}' — no files changed under ${extra_dir}/"
		continue
	fi

	log_info "Validating shared library (${extra_dir}/)..."

	if [ ! -f "$changelog_file" ]; then
		log_error "Missing ${changelog_file} for modified shared library."
		record_failure "Missing '${changelog_file}'. Create one with a '## [Unreleased]' section describing the changes."
		continue
	fi

	check_unreleased_section "$changelog_file"
	check_no_changes_outside_unreleased "$changelog_file" "$BASE_REF"
done

# --- Summary ---
echo
echo "--------------------------------------------------"
if [ "$FAILED" = true ]; then
	log_error "Changelog check FAILED with ${#FAILURES[@]} violation(s):"
	for f in "${FAILURES[@]}"; do
		echo "  - $f"
	done
	echo
	log_info "Remediation:"
	log_info "  - Add a bullet describing your change under '## [Unreleased]' in the affected mod's CHANGELOG.md."
	log_info "  - Do not edit already-released version blocks; historical entries are immutable."
	exit 1
fi

log_success "All changelog checks passed."
exit 0
