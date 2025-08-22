#!/usr/bin/env bash
set -euo pipefail

# Smoke test: install the opencage package from the Racket package catalog
# into an isolated PLTUSERHOME and verify the version matches the local
# source tree's declared version (info.rkt). This helps confirm that the
# published package is up to date and installable.
#
# Usage:
#   bash scripts/catalog-smoke.sh            # strict version check
#   ALLOW_VERSION_MISMATCH=1 bash scripts/catalog-smoke.sh  # only warn
#
# Environment:
#   ALLOW_VERSION_MISMATCH=1  Allow catalog version mismatch without failing
#   EXPECT_VERSION=X.Y[.Z]    Override expected version (otherwise read info.rkt)
#   VERBOSE=1                 Show raco pkg install output
#
# Exit codes:
#   0 success (and versions match unless ALLOW_VERSION_MISMATCH)
#   1 failure (install problem or version mismatch)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Determine expected version
if [[ -n "${EXPECT_VERSION:-}" ]]; then
  expected="$EXPECT_VERSION"
else
  expected=$(grep -E '^\(define version "' info.rkt | sed -E 's/.*"([^"]+)".*/\1/')
fi
if [[ -z "$expected" ]]; then
  echo "[catalog-smoke] Could not determine expected version" >&2
  exit 1
fi

echo "[catalog-smoke] Expected version: $expected" >&2

TMP=$(mktemp -d)
export PLTUSERHOME="$TMP/user"
mkdir -p "$PLTUSERHOME"

echo "[catalog-smoke] Installing opencage from catalog into isolated PLTUSERHOME=$PLTUSERHOME" >&2
if [[ -n "${VERBOSE:-}" ]]; then
  raco pkg install --auto opencage
else
  raco pkg install --auto opencage >/dev/null
fi

echo "[catalog-smoke] Requiring library and capturing installed version" >&2
installed=$(racket -e '(require opencage) (display (opencage-version))') || {
  echo "[catalog-smoke] Failed to require installed package" >&2
  exit 1
}

echo "Installed version=$installed Expected=$expected" >&2

if [[ "$installed" != "$expected" ]]; then
  msg="[catalog-smoke] Version mismatch: catalog has $installed but expected $expected"
  if [[ -n "${ALLOW_VERSION_MISMATCH:-}" ]]; then
    echo "$msg (ALLOW_VERSION_MISMATCH set, not failing)" >&2
  else
    echo "$msg" >&2
    exit 1
  fi
else
  echo "[catalog-smoke] Version match OK" >&2
fi

echo "$installed"  # plain version to stdout for tool parsing
