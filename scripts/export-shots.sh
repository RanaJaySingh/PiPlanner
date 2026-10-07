#!/bin/zsh
# Usage: scripts/export-shots.sh <result.xcresult> <output dir>
# Exports the named UI-test screenshots, e.g. "05a Grok proposal.png".
set -euo pipefail
bundle=$1; out=$2
tmp=$(mktemp -d)
xcrun xcresulttool export attachments --path "$bundle" --output-path "$tmp" >/dev/null
mkdir -p "$out"
python3 - "$tmp" "$out" <<'PY'
import json, re, shutil, sys
tmp, out = sys.argv[1:]
for test in json.load(open(f"{tmp}/manifest.json")):
    for a in test["attachments"]:
        name = a["suggestedHumanReadableName"]
        if a["exportedFileName"].endswith(".png") and re.match(r"\d", name):
            shutil.copy(f"{tmp}/{a['exportedFileName']}", f"{out}/{re.sub(r'_0_[0-9A-F-]+', '', name)}")
PY
rm -rf "$tmp"
ls "$out"
