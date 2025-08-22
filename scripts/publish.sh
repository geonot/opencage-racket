#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

INFO_VERSION=$(grep -E '^\(define version' info.rkt | sed -E 's/.*"([^"]+)".*/\1/')
CLIENT_VERSION=$(grep -E 'OPCAGE-VERSION' client.rkt | sed -E 's/.*"([^"]+)".*/\1/')

if [[ "$INFO_VERSION" != "$CLIENT_VERSION" ]]; then
  echo "Version mismatch: info.rkt=$INFO_VERSION client=$CLIENT_VERSION" >&2
  exit 1
fi

VERSION="$INFO_VERSION"
TAG="v$VERSION"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG already exists" >&2
  exit 1
fi

echo "Releasing $TAG"
git add info.rkt client.rkt README.md scribblings/opencage.scrbl
if ! git diff --cached --quiet; then
  git commit -m "Release $TAG"
fi

git tag -a "$TAG" -m "Release $TAG"
git push origin main
git push origin "$TAG"

cat <<EOF
Release $TAG pushed.

If this is the first release, submit the repository URL to the Racket package index:
  https://pkgs.racket-lang.org/ ("Add Package")

Package name: opencage

Subsequent releases are picked up via tags.

EOF
