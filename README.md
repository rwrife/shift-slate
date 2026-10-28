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

**Flutter shell plus unconnected planning domain.** Event editing, coverage UI and exports remain planned. `lib/planning.dart` validates UTC shift boundaries with explicit start/end UTC offsets; `lib/store.dart` exposes SQLite schema-v2 persistence and transactional whole-plan replacement for later UI wiring. No app-screen data survives restart until issue #3 connects it. Use pinned Flutter 3.47.7 / Dart 3.13.5: `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`. Windows: `flutter run -d windows`; Android: `flutter run -d android`. `.github/workflows/ci.yml` tests and builds Windows on `windows-latest`, builds Android debug on `ubuntu-latest`. iOS/iPad project exists, but no iOS compile gate yet. Read [PLAN.md](PLAN.md) and open issues.

[AppStore/description.txt](AppStore/description.txt) is planned listing copy. Existing OpenAI-generated `AppStore/icon.png` provides Windows/Android/iOS launcher art; icon audits and store copy remain tracked by issue #6. `.github/workflows/release.yml` must eventually build zipped Windows release on `windows-latest` for `v*` or manual dispatch and attach to GitHub release. TestFlight/Play submission is later opt-in work, not MVP.
