#!/usr/bin/env bash
# Builds dist/ForeverBarberFix-<version>.zip, laid out so that unzipping into
# Interface\AddOns produces the ForeverBarberFix folder the client expects.
set -euo pipefail
cd "$(dirname "$0")/.."

tools/check-toc.sh >/dev/null
VERSION=$(grep -oP '^## Version: \K[0-9]+\.[0-9]+\.[0-9]+$' ForeverBarberFix.toc)
OUT="dist/ForeverBarberFix-$VERSION.zip"

rm -rf dist/stage "$OUT"
mkdir -p dist/stage/ForeverBarberFix
cp ForeverBarberFix.toc ForeverBarberFix.lua LICENSE README.md CHANGELOG.md dist/stage/ForeverBarberFix/

python3 - "$OUT" <<'PY'
import os, sys, zipfile
out = sys.argv[1]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk("dist/stage"):
        for f in sorted(files):
            p = os.path.join(root, f)
            z.write(p, os.path.relpath(p, "dist/stage"))
PY
rm -rf dist/stage
echo "$OUT"
