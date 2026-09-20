#!/usr/bin/env bash
# Sanity-checks the TOC: interface and version lines present, every listed file exists.
set -euo pipefail
cd "$(dirname "$0")/.."
TOC=ForeverBarberFix.toc

grep -qE '^## Interface: [0-9]+' "$TOC" || { echo "$TOC: missing '## Interface:'" >&2; exit 1; }
VERSION=$(grep -oP '^## Version: \K[0-9]+\.[0-9]+\.[0-9]+$' "$TOC") \
  || { echo "$TOC: '## Version:' must be x.y.z" >&2; exit 1; }

# A version must have a changelog section before it can be released.
grep -qE "^## ${VERSION//./\\.}\$" CHANGELOG.md \
  || { echo "CHANGELOG.md: no '## $VERSION' section" >&2; exit 1; }

# Every non-comment, non-empty line names a file that must exist.
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  [[ -f "$line" ]] || { echo "$TOC lists '$line' but it does not exist" >&2; exit 1; }
done < "$TOC"

echo "toc ok: version $VERSION"
