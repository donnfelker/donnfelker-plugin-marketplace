#!/usr/bin/env bash
# parse-commits.sh — Parse conventional commits from git log into structured output
#
# Usage:
#   ./parse-commits.sh [<range>]
#
# Arguments:
#   <range>  Optional git revision range (e.g., v1.0.0..HEAD, v1.0.0..v2.0.0)
#            If omitted, defaults to <latest-tag>..HEAD
#            If no tags exist, includes all commits
#
# Output format (one block per commit, separated by blank lines):
#   COMMIT:<hash>
#   TYPE:<type>
#   SCOPE:<scope>           (empty if no scope)
#   BREAKING:<yes|no>
#   DESCRIPTION:<description>
#   BODY:<body>             (empty if no body)
#   FOOTERS:<footers>       (empty if no footers)
#   ---

set -euo pipefail

RANGE="${1:-}"

# Determine range if not provided
if [[ -z "$RANGE" ]]; then
  LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [[ -n "$LATEST_TAG" ]]; then
    RANGE="${LATEST_TAG}..HEAD"
  else
    # No tags — include all commits
    RANGE="HEAD"
  fi
fi

# Regex patterns — stored in variables to avoid bash parsing issues with parentheses
COMMIT_RE='^([a-z]+)(\(([^)]*)\))?(!)?: (.+)$'
FOOTER_RE='^([A-Za-z-]+|BREAKING CHANGE)(: | #)(.*)$'
BREAKING_RE='^BREAKING[\ -]CHANGE'

# Process a single commit from its hash and message lines.
# Globals: COMMIT_RE, FOOTER_RE, BREAKING_RE (read-only)
# Arguments: None — reads HASH and LINES global variables
process_commit() {
  local subject="${LINES[0]:-}"
  local type scope bang desc body footers in_footer breaking start

  # Parse conventional commit subject
  if [[ "$subject" =~ $COMMIT_RE ]]; then
    type="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[3]:-}"
    bang="${BASH_REMATCH[4]:-}"
    desc="${BASH_REMATCH[5]}"
  else
    # Not a conventional commit — classify as "other"
    type="other"
    scope=""
    bang=""
    desc="$subject"
  fi

  body=""
  footers=""
  in_footer=false
  breaking="no"

  if [[ "$bang" == "!" ]]; then
    breaking="yes"
  fi

  # Process remaining lines (skip subject and blank line after it)
  start=1
  if [[ ${#LINES[@]} -gt 1 && -z "${LINES[1]:-}" ]]; then
    start=2
  fi

  for ((i=start; i<${#LINES[@]}; i++)); do
    local line="${LINES[$i]}"

    # Check for footer pattern: "Token: value" or "Token #value" or "BREAKING CHANGE: value"
    if [[ "$line" =~ $FOOTER_RE ]]; then
      in_footer=true
    fi

    if $in_footer; then
      if [[ -n "$footers" ]]; then
        footers="${footers}\n${line}"
      else
        footers="$line"
      fi
      # Check for BREAKING CHANGE footer
      if [[ "$line" =~ $BREAKING_RE ]]; then
        breaking="yes"
      fi
    else
      if [[ -n "$body" ]]; then
        body="${body}\n${line}"
      else
        body="$line"
      fi
    fi
  done

  echo "COMMIT:${HASH}"
  echo "TYPE:${type}"
  echo "SCOPE:${scope}"
  echo "BREAKING:${breaking}"
  echo "DESCRIPTION:${desc}"
  echo "BODY:${body}"
  echo "FOOTERS:${footers}"
  echo "---"
}

# Use a delimiter unlikely to appear in commit messages
DELIM="---COMMIT-BOUNDARY---"

# Exclude merge commits — release notes should reflect individual changes, not merge boundaries
# Use process substitution (< <(...)) instead of a pipe so the while loop runs in the current
# shell. This ensures the "last commit" fallback block can access HASH/LINES after the loop.
while IFS= read -r line; do
  if [[ "$line" == "$DELIM" ]]; then
    if [[ -n "${HASH:-}" ]]; then
      process_commit
    fi

    # Reset for next commit
    unset HASH
    unset LINES
    continue
  fi

  if [[ -z "${HASH:-}" ]]; then
    HASH="$line"
    LINES=()
  else
    LINES+=("$line")
  fi
done < <(git log "$RANGE" --pretty=format:"%H%n%B%n${DELIM}" --no-merges)

# Process last commit if no trailing delimiter
if [[ -n "${HASH:-}" ]]; then
  process_commit
fi
