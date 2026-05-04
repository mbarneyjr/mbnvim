#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nodejs jq git cacert

set -euo pipefail

OVERLAY_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$OVERLAY_DIR/default.nix"

owner=$(grep 'owner =' "$NIX_FILE" | head -1 | sed 's/.*"\(.*\)".*/\1/')
repo=$(grep 'repo =' "$NIX_FILE" | head -1 | sed 's/.*"\(.*\)".*/\1/')
rev=$(grep 'rev =' "$NIX_FILE" | head -1 | sed 's/.*"\(.*\)".*/\1/')

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
