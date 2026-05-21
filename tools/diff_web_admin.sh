#!/usr/bin/env bash
# Capture web-admin reference responses so the Dart parity tests can
# replay them offline.
#
# Run against a running radius-module instance:
#   BASE=http://localhost:5555 ADMIN_USER=admin ADMIN_PASS=admin \
#     ./tools/diff_web_admin.sh
#
# Outputs JSON / HTML / PDF snapshots under tools/web_snapshots/.
# Re-run after every backend release; the diff vs the previous run is
# what tells us if the backend contract drifted.

set -euo pipefail

BASE="${BASE:-http://localhost:5555}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admin}"

here="$(cd "$(dirname "$0")" && pwd)"
out="$here/web_snapshots"
mkdir -p "$out"

cookie="$out/.session"
trap 'rm -f "$cookie"' EXIT

echo "→ logging into $BASE"
curl -s -c "$cookie" -b "$cookie" \
  -d "username=$ADMIN_USER&password=$ADMIN_PASS" \
  -o /dev/null \
  "$BASE/admin/radius/login"

echo "→ /admin/radius/print-templates (designer page HTML)"
curl -s -b "$cookie" \
  "$BASE/admin/radius/print-templates" \
  > "$out/print_templates.html"

echo "→ list templates via JSON API"
curl -s -b "$cookie" \
  -H "Accept: application/json" \
  "$BASE/api/v1/print-templates" \
  > "$out/print_templates_list.json"

echo "→ list presets"
curl -s -b "$cookie" \
  -H "Accept: application/json" \
  "$BASE/api/v1/print-templates/presets" \
  > "$out/print_template_presets.json"

# Pick the first template id to drive per-template snapshots
first_id=$(python3 -c "
import json,sys
data=json.load(open('$out/print_templates_list.json'))
items=data.get('data',{}).get('items',[]) if isinstance(data,dict) else []
print(items[0]['id'] if items else '')
")

if [[ -n "$first_id" ]]; then
  echo "→ template $first_id preview-fragment"
  curl -s -b "$cookie" \
    "$BASE/admin/radius/print-templates/$first_id/preview-fragment" \
    > "$out/preview_fragment_$first_id.html"

  echo "→ template $first_id sample PDF"
  curl -s -b "$cookie" \
    "$BASE/admin/radius/print-templates/$first_id/export.pdf?sample_username=CARD7" \
    -o "$out/sample_$first_id.pdf"

  size=$(stat -c %s "$out/sample_$first_id.pdf" 2>/dev/null || stat -f %z "$out/sample_$first_id.pdf")
  echo "  PDF $first_id: $size bytes"
fi

echo "→ /admin/radius/print-templates/export (must be 302 redirect)"
curl -s -b "$cookie" -o /dev/null -w "%{http_code} → %{redirect_url}\n" \
  "$BASE/admin/radius/print-templates/export" \
  > "$out/export_redirect.txt"
cat "$out/export_redirect.txt"

echo
echo "→ done. Snapshots in $out"
echo "   Commit the JSON / HTML / .txt files; PDF / images are gitignored."
