# Shift Slate plan

## Scope and architecture

Flutter stable + Dart, one application with `windows/`, `android/`, `ios/` folders enabled at first implementation. Pure Dart domain calculates occupancy and overlaps from immutable shift/assignment records. Persist event, shift, volunteer and attendance locally in SQLite via an existing Flutter package selected during implementation; migration version required. User-selected file export: CSV printable roster and versioned JSON backup with validate-before-replace import. No server, telemetry, account, subscription, or app network calls. Data is private until manual export; exported backup may contain contact notes, so warn and preview before sharing.

## UX strategy A: platform-native adaptive

iOS/iPadOS Cupertino navigation, dialogs, scroll feel and safe areas; Android Material 3 dynamic color and system back; Windows Fluent title/navigation/command bars and keyboard shortcuts. Screens share state/domain via small adaptive-widget layer, not platform-specific business logic. Native OS file/share pickers; hover and context menus on desktop, touch targets on phones. Phone list, tablet two-pane, Windows resizable grid. No Material on iOS, Cupertino on Android, or phone UI on Windows. Screen reader labels, contrast, text scaling, focus order and full keyboard navigation. Golden/widget tests at TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.windows with phone/tablet/desktop sizes.

Identifier: `com.infinityball.shiftslate` for Android applicationId and iOS bundle ID; Windows packaging identity same namespace. App Store Connect: `CREATED com.infinityball.shiftslate`; repository secret names `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID`.

## Milestones / dependencies

1. Flutter platform skeleton, pinned toolchain and basic CI (`windows-latest` tests + Windows release build; Linux Docker Android debug build); no CI claim until logs exist.
2. Domain model and deterministic coverage/overlap tests, local persistence and migrations.
3. Event/volunteer/shift authoring and assignment flow with no automatic volunteer sync.
4. Coverage dashboard and attendance; adaptive platform UI with goldens/accessibility checks.
5. Safe CSV roster export and JSON backup/validate-before-replace restore.
6. Real source icon `AppStore/icon.png` generated with OpenAI Images via spark-media; wire Windows `.ico`, Android and iOS launcher icons. Keep [AppStore/description.txt](AppStore/description.txt) accurate to built features.
7. `.github/workflows/release.yml`: `v*` or manual dispatch, `windows-latest`, `flutter test` and `flutter build windows --release`, zip portable output and attach to GitHub release. Android debug build in Linux/Docker CI; iOS compile on macOS runner as later gate. TestFlight via four ASC secrets and Play submission later opt-in milestones.

## Test and release matrix

Windows desktop is committed CI/release target; Android and iOS phone/tablet are committed product targets with mobile compile lanes introduced incrementally. Linux/macOS desktop are not committed exports. No platform has been built or tested in this documentation-only scaffold. Use pure Dart tests for times crossing midnight, zero coverage, duplicate assignment, conflicts, DST boundary display; widget/golden tests for all three TargetPlatform values; integration tests for atomic backup import and export escaping. Windows zip is MVP downloadable artifact only after release Action actually runs. No claim of store upload.

## Risks / non-goals

Shift timezones and daylight-saving transitions need explicit local-time semantics; unknown or overlapping slots must not become silently valid. CSV injection and private contact data in exported files need sanitization/warnings. No hosted volunteer signup, payments, automated email, cross-device collaboration, live sync, geolocation, calendar API, or legal volunteer compliance. App uses platform-native adaptive widgets, not a fully custom UI.
