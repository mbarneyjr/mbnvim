#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nodejs jq git cacert

set -euo pipefail

OVERLAY_DIR="$(cd "$(dirname "$0")" && pwd)"
FLAKE_DIR="$(git -C "$OVERLAY_DIR" rev-parse --show-toplevel)"
LOCK_FILE="$FLAKE_DIR/flake.lock"

# The source is now a bare flake input pinned in flake.lock. Run
# `nix flake update actions-languageservices` first to bump it, then this
# script regenerates package-lock.json against the newly-locked revision.
locked=$(jq -r '.nodes["actions-languageservices"].locked' "$LOCK_FILE")
owner=$(jq -r '.owner' <<<"$locked")
repo=$(jq -r '.repo' <<<"$locked")
rev=$(jq -r '.rev' <<<"$locked")

echo "Fetching $owner/$repo@$rev"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

git clone --depth 1 --no-checkout "https://github.com/$owner/$repo.git" "$workdir/repo"
cd "$workdir/repo"
git fetch origin "$rev"
git checkout "$rev"

jq 'del(.devDependencies["rest-api-description"])' languageservice/package.json >tmp.json
mv tmp.json languageservice/package.json
rm package-lock.json

npm install --package-lock-only

cp package-lock.json "$OVERLAY_DIR/package-lock.json"
echo "Updated $OVERLAY_DIR/package-lock.json"
echo ""
echo "Now rebuild to get the new npmDepsHash — update default.nix with the hash from the error."
