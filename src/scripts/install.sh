#!/usr/bin/env bash
set -euo pipefail

CLI_VERSION="${CLI_VERSION:-latest}"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"
BIN_PATH="${BIN_DIR}/linear-release"

OS="$(uname -s)"
case "$OS" in
  Linux)
    ARCH="$(uname -m)"
    [[ "$ARCH" == "amd64" ]] && ARCH="x86_64"
    
    if [[ "$ARCH" != "x86_64" ]]; then
      echo "Error: Unsupported Linux arch: $ARCH. Only x86_64/amd64 is supported." >&2
      exit 1
    fi
    ASSET="linear-release-linux-x64"
    ;;
  Darwin)
    ARCH="$(uname -m)"
    if [[ "$ARCH" == "arm64" ]]; then
      ASSET="linear-release-darwin-arm64"
    elif [[ "$ARCH" == "x86_64" ]]; then
      ASSET="linear-release-darwin-x64"
    else
      echo "Error: Unsupported macOS arch: $ARCH. Only x86_64 and arm64 are supported." >&2
      exit 1
    fi
    ;;
  *)
    echo "Error: Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

if [[ "$CLI_VERSION" == "latest" ]]; then
  URL="https://github.com/linear/linear-release/releases/latest/download/$ASSET"
else
  URL="https://github.com/linear/linear-release/releases/download/$CLI_VERSION/$ASSET"
fi

echo "Downloading Linear Release CLI from $URL"

# Download to temp file
TEMP_BIN="$(mktemp)"
trap 'rm -f "$TEMP_BIN"' EXIT

if ! curl -fL --progress-bar "$URL" -o "$TEMP_BIN"; then
  echo "Error: Failed to download from $URL" >&2
  exit 1
fi

# Verify download
if [[ ! -s "$TEMP_BIN" ]]; then
  echo "Error: Downloaded file is empty" >&2
  exit 1
fi

chmod +x "$TEMP_BIN"
mv "$TEMP_BIN" "$BIN_PATH"

# Add to PATH for CircleCI (persists across steps)
if [[ -n "${BASH_ENV:-}" ]]; then
  echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "$BASH_ENV"
fi

echo "Linear Release CLI installed at $BIN_PATH"
echo "Version: $($BIN_PATH --version 2>/dev/null || echo 'unknown')"