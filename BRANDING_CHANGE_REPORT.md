# SRB Computer Branding Change Report

Date: 2026-11-16

## Completed changes

The user-facing brand name was changed from Crackteck/CrackTeck to **SRB Computer** in:

- Android app label and notification channel label.
- iOS app display name, app name, and permission descriptions.
- Web app manifest, browser title, and metadata.
- Salesperson, delivery-person, and field-executive dashboard headers.
- Local test notification title.
- Mock service-hub address used by the delivery flow.
- README, API integration summary, change summary, testing strategy, testability report, and `pubspec.yaml` description.

## Package and API migration

The technical identifiers were migrated as requested:

- Dart package name: `srb_computer_engineer`
- Android/iOS package identifier: `com.srbcomputer.engineer`
- Firebase project: `srb-computers-1be29`
- API host: `srbcomputers.co.in`
- Internal Dart class name: `CrackteckBottomSwitcher` (legacy class name only)

The following Firebase files still contain the old Firebase app registration and must be replaced after creating the new Firebase app:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Download fresh files for package/bundle ID `com.srbcomputer.engineer` from Firebase and replace the existing files before building.
