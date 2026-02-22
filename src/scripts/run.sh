#!/usr/bin/env bash
set -euo pipefail

# Ensure linear-release is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Check for Linear access key
if [[ -z "${LINEAR_ACCESS_KEY:-}" ]]; then
  echo "Error: LINEAR_ACCESS_KEY environment variable is required" >&2
  exit 1
fi

# Debug: Show key info (masked for security)
key_length=${#LINEAR_ACCESS_KEY}
key_suffix="${LINEAR_ACCESS_KEY: -4}"
echo "Debug: Access key found - length: $key_length, ends with: ****$key_suffix"

# Verify CLI is installed
if ! command -v linear-release &> /dev/null; then
  echo "Error: linear-release CLI not found. The install step may have failed." >&2
  exit 1
fi

# Validate command
COMMAND="${COMMAND:-sync}"
case "$COMMAND" in
  sync|complete|update)
    ;;
  *)
    echo "Error: Invalid command '$COMMAND'. Must be: sync, complete, or update" >&2
    exit 1
    ;;
esac

# Validate stage for update command
if [[ "$COMMAND" == "update" && -z "${INPUT_STAGE:-}" ]]; then
  echo "Error: stage parameter is required when command is 'update'" >&2
  exit 1
fi

# Build command arguments
args=()
[[ -n "${INPUT_NAME:-}" ]] && args+=("--name=${INPUT_NAME}")
[[ -n "${INPUT_VERSION:-}" ]] && args+=("--release-version=${INPUT_VERSION}")
[[ -n "${INPUT_STAGE:-}" ]] && args+=("--stage=${INPUT_STAGE}")
[[ -n "${INPUT_INCLUDE_PATHS:-}" ]] && args+=("--include-paths=${INPUT_INCLUDE_PATHS}")

# Run the command
echo "Running: linear-release $COMMAND ${args[*]}"

# Capture both stdout and stderr, preserve exit code
set +e
output=$(linear-release "$COMMAND" --json "${args[@]}" 2>&1)
exit_code=$?
set -e

if [[ $exit_code -ne 0 ]]; then
  echo "Error: linear-release command failed with exit code $exit_code" >&2
  echo "$output" >&2
  exit "$exit_code"
fi

# Print the raw output so it appears in CircleCI logs
echo "$output"

# Validate and parse JSON output (if jq is available)
if command -v jq &> /dev/null; then
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    # Parse and display key information
    release_id=$(jq -r '.release.id // empty' <<<"$output")
    release_name=$(jq -r '.release.name // empty' <<<"$output")
    release_version=$(jq -r '.release.version // empty' <<<"$output")
    release_url=$(jq -r '.release.url // empty' <<<"$output")
    
    if [[ -n "$release_url" ]]; then
      echo ""
      echo "✓ Release synced successfully"
      [[ -n "$release_name" ]] && echo "  Name: $release_name"
      [[ -n "$release_version" ]] && echo "  Version: $release_version"
      echo "  URL: $release_url"
      [[ -n "$release_id" ]] && echo "  ID: $release_id"
    fi
  else
    echo "Warning: Linear Release CLI did not return valid JSON" >&2
  fi
fi

echo "Linear release $COMMAND completed successfully"
