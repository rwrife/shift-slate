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

**Documentation and artwork scaffold only.** No Flutter project, tests, builds, exports, or platform icon wiring yet. Read [PLAN.md](PLAN.md) and open issues. After issue #1: install pinned Flutter stable SDK, run `flutter pub get`, `flutter test`, `flutter run -d windows` on Windows or `flutter run -d android` on Android. Linux hosts use a pinned Flutter Docker image for test/Android build. Release workflow and mobile builds are planned, not proven.

[AppStore/description.txt](AppStore/description.txt) is planned listing copy; `AppStore/icon.png` is source art, not yet wired to Windows/Android/iOS launcher sets. Icon generation uses OpenAI Images through `~/.local/bin/spark-media --project shift-slate image --prompt "..."`. Never use placeholder icons. `.github/workflows/release.yml` must eventually build zipped Windows release on `windows-latest` for `v*` or manual dispatch and attach to GitHub release. TestFlight/Play submission is later opt-in work, not MVP.
