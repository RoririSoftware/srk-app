# SKR Trader - field app (demo)

Flutter app for the SKR Trader field team: farmer leads, Patta OCR, and matching a
Small/Marginal Farmer Certificate against the Patta records already on file.

This is a **demo build**. All data lives in memory (`lib/store.dart`) and resets on
restart; sign-in accepts any non-empty credentials.

## Run

```sh
flutter pub get
flutter run                 # or: flutter build apk --release
```

## OCR

Documents are read by the Gemini vision API (`lib/ocr.dart`). On-device ML Kit is not
an option here - it has no Tamil script model, and most of a Patta is Tamil.

With no API key the app falls back to the bundled sample documents in
`lib/sample_data.dart` and says so on screen, so a demo never breaks offline.

```sh
flutter build apk --release --dart-define=GEMINI_API_KEY=xxxx
# optional: --dart-define=GEMINI_MODEL=gemini-2.5-flash
```

A key can also be pasted on the Profile screen for the current session.

## Layout

| File | What |
| --- | --- |
| `lib/ui.dart` | Neumorphic widget kit (one matte surface, dual shadows, inset wells) |
| `lib/match.dart` | Certificate vs Patta comparison - the actual product logic |
| `lib/ocr.dart` | Gemini call, prompts, JSON schemas, sample fallback |
| `lib/models.dart` `lib/store.dart` `lib/sample_data.dart` | Data and seeded demo records |
| `lib/lead_form.dart` | The lead wizard, described as data |
| `lib/screens/` | One file per screen |

## Tests

```sh
flutter test
```

`test/match_test.dart` covers the comparison rules (name normalisation, survey number
sets, extent tolerance, certificate expiry). `test/smoke_test.dart` walks the demo path
at phone size, so a layout overflow fails the build rather than the meeting.

## Not built yet

No backend, no persistence, no PDF export, no offline queue. The lead wizard's product,
delivery and warranty steps are captured but nothing acts on them.
