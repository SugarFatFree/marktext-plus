#!/usr/bin/env bash
# Register MarkText Plus as the default handler for Markdown files on Linux.
#
# Without this, desktop environments have no MimeType association for the app
# and keep showing the "Open With…" chooser every time a .md file is opened.
#
# Usage:
#   scripts/install-linux-desktop.sh [path/to/marktext_plus]
#   scripts/install-linux-desktop.sh --uninstall
#
# With no argument the script looks for the release bundle produced by
# `flutter build linux --release`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGING_DIR="$REPO_ROOT/code/linux/packaging"
ICON_DIR="$REPO_ROOT/code/linux/resources"
APP_ID="com.marktextplus.marktext_plus"

DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
MIME_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/mime"
MIME_DIR="$MIME_ROOT/packages"
ICONS_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"

refresh_databases() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" || true
  fi
  if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database "$MIME_ROOT" || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$ICONS_ROOT" >/dev/null 2>&1 || true
  fi
}

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -f "$DESKTOP_DIR/$APP_ID.desktop"
  rm -f "$MIME_DIR/marktext-plus.xml"
  for size in 48 64 128 256 512; do
    rm -f "$ICONS_ROOT/${size}x${size}/apps/$APP_ID.png"
  done
  refresh_databases
  echo "MarkText Plus desktop integration removed."
  exit 0
fi

EXEC_PATH="${1:-$REPO_ROOT/code/build/linux/x64/release/bundle/marktext_plus}"

if [[ ! -x "$EXEC_PATH" ]]; then
  echo "error: executable not found: $EXEC_PATH" >&2
  echo "Build it first with: (cd code && flutter build linux --release)" >&2
  echo "Or pass the binary path explicitly." >&2
  exit 1
fi

EXEC_PATH="$(cd "$(dirname "$EXEC_PATH")" && pwd)/$(basename "$EXEC_PATH")"

mkdir -p "$DESKTOP_DIR" "$MIME_DIR"

# The Exec key must tolerate spaces in the path, so quote it.
sed "s|@EXEC_PATH@|\"$EXEC_PATH\"|" "$PACKAGING_DIR/marktext-plus.desktop" \
  > "$DESKTOP_DIR/$APP_ID.desktop"
chmod 644 "$DESKTOP_DIR/$APP_ID.desktop"

cp "$PACKAGING_DIR/marktext-plus.xml" "$MIME_DIR/marktext-plus.xml"

for size in 48 64 128 256 512; do
  src="$ICON_DIR/app_icon_${size}.png"
  [[ -f "$src" ]] || continue
  mkdir -p "$ICONS_ROOT/${size}x${size}/apps"
  cp "$src" "$ICONS_ROOT/${size}x${size}/apps/$APP_ID.png"
done

refresh_databases

# Make it the default for Markdown, leaving text/plain to the user's editor.
if command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default "$APP_ID.desktop" text/markdown || true
  xdg-mime default "$APP_ID.desktop" text/x-markdown || true
fi

echo "MarkText Plus registered for text/markdown."
echo "  desktop entry : $DESKTOP_DIR/$APP_ID.desktop"
echo "  executable    : $EXEC_PATH"
echo
echo "If the file manager still shows the chooser, log out and back in so the"
echo "desktop environment reloads its MIME cache."
