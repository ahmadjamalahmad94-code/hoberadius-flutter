# Web admin reference snapshots

Capture the **exact** shape of every web-admin endpoint the Flutter
Windows build mirrors. The Dart parity tests in
`test/parity/` replay these files offline so a backend contract drift
fails locally before it ever reaches a user.

## Refreshing

```bash
BASE=http://localhost:5555 ADMIN_USER=admin ADMIN_PASS=admin \
  ./tools/diff_web_admin.sh
```

That writes:

| File                              | Source                                                                   |
|-----------------------------------|--------------------------------------------------------------------------|
| `print_templates.html`            | `GET /admin/radius/print-templates`                                       |
| `print_templates_list.json`       | `GET /api/v1/print-templates`                                             |
| `print_template_presets.json`     | `GET /api/v1/print-templates/presets`                                     |
| `preview_fragment_<id>.html`      | `GET /admin/radius/print-templates/<id>/preview-fragment`                 |
| `sample_<id>.pdf`                 | `GET /admin/radius/print-templates/<id>/export.pdf?sample_username=CARD7` |
| `export_redirect.txt`             | `GET /admin/radius/print-templates/export` (must 302 → `#export`)         |

## What's tracked

JSON, HTML, plain text → committed to git as the contract source of
truth.

Binary captures (PDF, PNG, etc.) → gitignored. They are useful for
local pixel diff but too noisy for git history. CI re-captures them.

## How the Dart side uses these files

`test/parity/web_contract_test.dart` (added in commit E3) reads each
JSON / HTML file and asserts the Dart parser produces the expected
domain model.

`test/parity/pdf_pixel_diff_test.dart` (added in commit E1) compares
the PDF captured here against the one the Flutter Windows build
fetches at runtime — same template, same overrides, byte-comparable.
