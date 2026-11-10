# Shift Slate

Offline volunteer shift planner for small events: assign helpers, see coverage gaps, and export a printable roster on phone, tablet, and Windows without accounts.

## Why / who

School fairs, neighborhood cleanups, gallery openings, and club events often need one coordinator and a handful of shifts, not a hosted signup service. Shift Slate is a coordinator-owned roster: it does **not** let volunteers sign up remotely or synchronize multiple devices.

## Intended workflow

1. Create an event and its location, date, and shift slots with required helper counts.
2. Add volunteer display names and optional private contact notes. Assign people to slots; overlap and uncovered-slot warnings remain visible, never silently resolve assignments.
3. Review coverage on phone or expanded tablet/Windows grid. Export a printable roster or a local backup; share files manually using the platform's share/file dialogs. Record attendance locally if needed.

## MVP / boundaries

Planned: event templates, volunteer roster, repeatable shift slots, overlap and coverage calculations, accessible assignment UI, CSV roster, versioned JSON backup/restore. No account, payment, messaging, live signup, online invite, cloud sync, calendar-server integration, or automated contact uploads. No claims of completed app features yet.

## Platforms / privacy

Flutter stable, single codebase with `windows/`, `android/`, `ios/` folders enabled in the first implementation issue. Windows primary CI/release; Android and iOS phones **and tablets** first-class. Touch and keyboard/mouse supported; responsive layout with native Cupertino iOS, Material 3 Android, Fluent Windows controls (strategy A). Screen-reader labels, scalable text, high contrast, and full keyboard navigation required. Local device storage only; no app network requests. Display names/contact notes stay on device unless user explicitly exports/shares a file. No background location, camera, address-book, or notification permissions. Exported rosters can expose names: preview before sharing; backup includes private notes and must be clearly labeled. No volunteer-consent or legal-compliance guarantee.

Identifiers: Android applicationId and iOS bundle ID `com.infinityball.shiftslate`; Windows identity uses same namespace. App Store Connect registration: `CREATED com.infinityball.shiftslate`. Four repository Actions secret names (values never committed): `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID`.

## Status / quickstart

**Offline event, volunteer and shift authoring connected to SQLite with formula-safe CSV roster export.** Events, volunteers with private contact notes, timed shifts with explicit UTC offsets, assignments/unassignments, and attendance toggles persist locally. Coordinators can preview and export an RFC 4180 / UTF-8 CSV roster with spreadsheet formula protection; private contact notes remain excluded from export. Restoring state from restart and basic coverage counts, gap/extra labels, schedule-conflict warnings, and attendance toggles persist locally. Full versioned atomic JSON backup/restore remains planned. Use pinned Flutter 3.47.7 / Dart 3.13.5: `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`. Windows: `flutter run -d windows`; Android: `flutter run -d android`. `.github/workflows/ci.yml` tests and builds Windows on `windows-latest`, builds Android debug on `ubuntu-latest`, and has an unsigned iOS/iPadOS simulator compile gate on `macos-latest` (not signing or device execution). Read [PLAN.md](PLAN.md) and open issues.

[AppStore/description.txt](AppStore/description.txt) describes implemented authoring, assignments, coverage, attendance, and local CSV roster export; atomic JSON backup/restore remains planned. OpenAI-generated `AppStore/icon.png` is wired to Windows, Android (legacy/adaptive), and iOS/iPad launcher art; [generation and derivative details](AppStore/icon-origin.md). Native icon launch has not been device-audited. `.github/workflows/release.yml` builds, tests, and zips the Windows app on `windows-latest` for an existing `vMAJOR.MINOR.PATCH` tag (push or manual dispatch), then attaches the ZIP to a GitHub release. Artifact publication still needs an actual tagged workflow run to verify. TestFlight/Play submission is later opt-in work, not MVP.

## CI matrix

- `windows-latest`: verify pinned Flutter 3.47.7, check formatting, analyze, run tests, build Windows release executable.
- `ubuntu-latest`: build Android debug APK using Temurin Java 17 and pinned Flutter.
- `macos-latest`: compile unsigned iOS simulator app, verifying `com.infinityball.shiftslate` bundle ID and iPad support.
