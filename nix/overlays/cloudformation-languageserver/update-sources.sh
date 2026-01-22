#!/usr/bin/env bash
set -e

VERSION="${1:?Usage: $0 <version> (e.g., 1.3.1)}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
OUT_FILE="${SCRIPT_DIR}/sources.json"
WORK_DIR=$(mktemp -d)

PLATFORMS=(
  "x86_64-linux:linux-x64"
  "aarch64-linux:linux-arm64"
  "x86_64-darwin:darwin-x64"
  "aarch64-darwin:darwin-arm64"
)

echo '{"version":"'"${VERSION}"'"}' >"$OUT_FILE"

for pair in "${PLATFORMS[@]}"; do
  (
    SYSTEM="${pair%%:*}"
    SUFFIX="${pair##*:}"

    URL="https://github.com/aws-cloudformation/cloudformation-languageserver/releases/download/v${VERSION}/cloudformation-languageserver-${VERSION}-${SUFFIX}-node22.zip"

    HASH=$(nix store prefetch-file --unpack --json "$URL" | jq -r .hash)
    echo "Prefetched $SYSTEM"

    # jq --arg s "$SYSTEM" --arg u "$URL" --arg h "$HASH" \
    #   '.[$s] = {url: $u, sha256: $h}' "$OUT_FILE" >"$tmp" && mv "$tmp" "$OUT_FILE"
    jq -n \
      --arg s "$SYSTEM" \
      --arg u "$URL" \
      --arg h "$HASH" \
      '{($s): {url: $u, sha256: $h}}' >"$WORK_DIR/$SYSTEM.json"
  ) &
done

wait

jq -n --arg v "$VERSION" '{version: $v}' >"$WORK_DIR/aaaversion.json"
jq -s 'add' "$WORK_DIR"/*.json >"$OUT_FILE"

echo "Done! Wrote to $OUT_FILE"
