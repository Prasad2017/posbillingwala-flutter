# POS Billingwala Version 2 (Flutter)

Cross-platform rewrite of the Android `WithTable` POS for **Android** and **iOS**.

## Status

Feature-complete for day-to-day POS: auth, masters, billing, tables/KOT, takeaway, mess QR, reports, inventory/expenses, bill sync, FCM, and print (BT + network ESC/POS).

See `docs/ROADMAP.md` and `docs/STORE_RELEASE.md`.

## Run

```bash
cd pos_billingwala_v2
flutter pub get
flutter run
```

## Release builds

```bash
# Android App Bundle (needs android/key.properties — see STORE_RELEASE.md)
flutter build appbundle --release

# iOS IPA (Xcode signing required)
flutter build ipa --release
```

## Project structure

```
lib/
  app/                 # MaterialApp, theme, router
  core/                # constants, network, database, utils
  features/
    auth/              # Licence / MPIN / session
    home/              # Module hub + notification bell
    pos/               # Cart, payment, KOT
    tables/            # Dine-in floor + join
    takeaway/
    mess/              # Members + QR tokens
    masters/
    inventory/         # Stock + expenses
    reports/
    sync/              # Upload / download bills
    notifications/     # FCM
    print/             # ESC/POS + share
    settings/
  shared/
    models/            # Catalog + inventory API DTOs
    widgets/
```

## Stack

| Concern | Package |
|---------|---------|
| UI | Flutter Material 3 |
| State | flutter_riverpod |
| Navigation | go_router |
| HTTP | dio |
| Local DB | drift + sqlite3 |
| Push | firebase_messaging |
| Print | ESC/POS bytes + print_bluetooth_thermal / LAN socket / share_plus |

## Notes

- Android `applicationId`: `com.pos_billingwala` (same Firebase app as WithTable)
- Existing native app remains in `../WithTable` until you cut over production

## Version

`2.0.1+2`


## Development verification

Before release, run the following checks locally or in CI:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The `ui/modern-logo-theme` branch contains the modern UI redesign and should pass these checks before merging to the release branch.
