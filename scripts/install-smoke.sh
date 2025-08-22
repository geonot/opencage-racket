#!/usr/bin/env bash
set -euo pipefail

echo "[install-smoke] Building archive and testing fresh install" >&2

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PKG_NAME=opencage

# Create package archive (zip) in a temp workspace
ARCHIVE=$(raco pkg create "$PKG_NAME" 2>/dev/null | tail -n1)
if [[ ! -f "$ARCHIVE" ]]; then
  echo "Archive creation failed (expected $ARCHIVE)" >&2
  exit 1
fi

TMP=$(mktemp -d)
export PLTUSERHOME="$TMP/user"
mkdir -p "$PLTUSERHOME"

echo "[install-smoke] Installing $ARCHIVE into isolated PLTUSERHOME=$PLTUSERHOME" >&2
raco pkg install --auto "$ARCHIVE" >/dev/null

echo "[install-smoke] Requiring library and printing version:" >&2
racket -e '(require opencage) (printf "version=~a\n" (opencage-version))'

echo "[install-smoke] Success" >&2
