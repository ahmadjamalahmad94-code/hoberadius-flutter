# Mobile Baseline (Android + iOS)

> Frozen snapshot of what the mobile build looks like at the
> commit immediately preceding the Windows-parity work. Every
> commit in the parity plan MUST keep this baseline intact —
> any drift here means we accidentally touched mobile and must
> revert / guard the change behind `Platform.isWindows`.

## How to refresh this baseline

```bash
# Capture the mobile widget goldens
flutter test --update-goldens test/widgets/
flutter test --update-goldens test/screens/

# Capture an Android release APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://staging.example
ls -la build/app/outputs/flutter-apk/app-release.apk
```

## What to record

### 1. APK size

| Variant | Size | SHA-256 |
|---------|-----:|---------|
| `app-release.apk` (arm64, all assets) | TBD | TBD |

Re-run after every plan phase. A jump > 200 KB indicates a
desktop-only asset (e.g. Almarai TTF, `printing` plugin, etc.)
leaked into the mobile build — open the APK with
`unzip -l app-release.apk` and audit.

### 2. Asset manifest

Run from project root:

```bash
unzip -l build/app/outputs/flutter-apk/app-release.apk \
  | awk '$4 ~ /^assets\// { print $4 }' \
  | sort > docs/mobile_assets.txt
```

Diff `mobile_assets.txt` between baseline and the latest build —
the set of bundled assets must match exactly (no `Almarai-*.ttf`,
no extra fonts, no Windows-only icons).

### 3. Screen goldens

Captured at two mobile breakpoints:

- `bpPhone`  = 360 dp (matches Android compact)
- `bpTablet` = 600 dp (matches Android medium)

Stored under `test/screens/goldens/`. The harness in
`test/screens/mobile_screen_harness.dart` pumps each top-level
route inside a `MediaQuery` at the target width and renders the
first paint.

### 4. `flutter analyze` + `flutter test` results

| Command | Pre-plan baseline | Latest |
|---------|------------------:|-------:|
| `flutter analyze`                | clean | clean |
| `flutter test`                   | NN passed | NN passed |
| `flutter test test/widgets/`     | 12 goldens | 12 goldens |
| `flutter test test/screens/`     | NN goldens | NN goldens |

Update on every commit. Any new failure here gates the commit.

## Mobile-safety contract

Three rules every commit in the parity plan must satisfy:

1. **No new mobile asset**. `mobile_assets.txt` diff must be empty.
2. **No new mobile dependency**. `pubspec.yaml` additions sit under
   a Platform-guarded import path; mobile entry point never reaches
   the import statement.
3. **No new mobile UI**. Top-level mobile screens render the same
   widget tree at `bpPhone` / `bpTablet`. The Windows-only 3-column
   layout is rendered only when `MediaQuery.size.width >=
   AppTokens.bpDesktop`.

If any of the three rules is broken, the commit must:

- Either: move the change behind `Platform.isWindows` or
  `kIsWeb`-aware code paths.
- Or: be reverted and the work redone.

## Frozen baseline numbers (filled in by A1)

These values are written by `tools/freeze_mobile_baseline.sh`:

- APK size: _to be recorded by first run_
- `mobile_assets.txt`: see file
- `flutter test` count: _to be recorded by first run_

The baseline is intentionally cheap to refresh so we can re-run it
between every plan phase.
