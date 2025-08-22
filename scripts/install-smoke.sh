#!/usr/bin/env bash
set -euo pipefail

echo "[install-smoke] Testing fresh isolated install" >&2

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PKG_NAME=opencage

TMP=$(mktemp -d)
export PLTUSERHOME="$TMP/user"
mkdir -p "$PLTUSERHOME"

echo "[install-smoke] Installing source dir ($ROOT_DIR) into isolated PLTUSERHOME=$PLTUSERHOME" >&2
raco pkg install --auto "$ROOT_DIR" >/dev/null

echo "[install-smoke] Requiring library and printing version:" >&2
racket -e '(require opencage) (printf "version=~a\n" (opencage-version))'

echo "[install-smoke] Success" >&2
