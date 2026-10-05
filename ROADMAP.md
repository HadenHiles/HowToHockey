# How To Hockey — Build Roadmap (Flutter + Firebase, iOS & Android)

This roadmap turns the product spec into ordered, checkable milestones. Each phase ends in a shippable or testable state. Work top to bottom; do not start a phase until the previous phase's **Exit Criteria** are met. The approved UX Preview milestone below temporarily takes priority over Phases 2–14.

## 📍 Current Status
> Update this block at the end of every work session.

- **Current phase:** UX Preview — Flutter-first design review (in progress); Phase 2 backend/content work paused
- **Next task:** Review the first Player training slice with the user, then build the full Progress screens (radar, PR Vault, history/detail, share-card preview) before Team, Me, Parent/Coach, and account/commerce/program flows.
- **Blockers:** None for the UX preview: local sample data and illustrated media replace live content. Real drill media remains necessary when Phase 2 resumes. Production release setup remains deferred.
- **Last updated:** 2026-10-05

### Session Log
| Date | Summary | Commit |
|---|---|---|
| 2026-10-02 | Roadmap, product decisions, design system, brand assets finalized | `2e4daf1` |
| 2026-10-02 | Created the iOS/Android Flutter app, aligned bundle IDs, moved brand assets, configured Firebase apps, and added `firebase_core` | — |
| 2026-10-02 | Wired Firebase Auth, Firestore, Functions, and Storage to local emulators with Emulators/Live launch profiles | — |
| 2026-10-02 | Added startup anonymous sign-in when no user exists; project provider enablement remains pending | — |
| 2026-10-02 | Enabled the Anonymous provider in Firebase Authentication | — |
| 2026-10-02 | Installed Riverpod, GoRouter, Freezed, JSON serialization, and code-generation packages | — |
| 2026-10-02 | Wired Crashlytics, Analytics, and App Check; analyze/tests and Android build pass; iOS build blocked by Swift package tag resolution | `976647b` |
| 2026-10-02 | Configured local Firebase emulators and deny-by-default rules; added TypeScript Functions, linting, unit tests, and health-check callable | `6a7954d` |
| 2026-10-02 | Provisioned live Firestore and Storage in Toronto with deny-by-default rules; verified Android live Auth and registered its App Check debug token | — |
| 2026-10-02 | Added design tokens, light/dark themes, theme extensions, bundled Inter, and persisted Riverpod appearance selection | `8f50c2d` |
| 2026-10-02 | Generated branded iOS/Android launcher icons and light/dark native splash screens with reusable source assets | `0eabf3b`, `2b28e83` |
| 2026-10-02 | Added a VS Code live launch configuration targeting the connected Samsung S24 | — |
| 2026-10-02 | Registered Apple Team ID and App Attest in live Firebase; wired the production App Attest entitlement in Xcode; plist validation passes, but real-device verification remains blocked by Swift package tag resolution | — |
| 2026-10-02 | Diagnosed SwiftPM failure as Git's explicit-only bare-repository policy; verified the unsigned iOS release build with an approved process-scoped exception, documented the command, and refreshed Swift package locks | — |
| 2026-10-02 | Verified fresh production App Attest token exchange on a signed iPhone; added provider-specific device tests and an opt-in production verification build; replaced Android release debug signing with private upload-key configuration and documented remaining console steps; analyze, five unit/widget tests, and Android debug build pass; unsigned Android release is explicitly rejected | — |
| 2026-10-02 | Clarified the live-Firebase Samsung debug workflow; deferred production App Check, upload signing, and Play Console setup at the user's request so local development can continue with CI next | — |
| 2026-10-02 | Added SHA-pinned CI for Flutter analysis/tests/Android debug build, Functions lint/tests/build, and isolated demo-project rules tests; all local checks and 13 rules tests pass; all three jobs passed in [GitHub CI run 37056693374](https://github.com/HadenHiles/HowToHockey/actions/runs/37056693374); rules tooling retains three moderate upstream telemetry audit entries | `3dcbcc4` |
| 2026-10-05 | Added a VS Code live-Firebase debug launch configuration targeting the plugged-in iPhone | — |
| 2026-10-05 | Excluded generated Firebase CLI Dart templates under rules-test dependencies from app analysis; Flutter analysis and VS Code problems now report no issues | — |
| 2026-10-05 | Verified emulator-backed app launch on Android API 36 and iOS Simulator; enabled cleartext only in Android debug builds; added Freezed drill models, Firestore timestamp conversion, catalog schema, and guarded Firebase seeder; local emulator upload smoke test passed | — |
| 2026-10-05 | Approved Flutter-first UX Preview and paused backend/content milestones; added offline preview launches, branded Player navigation, Train/setup/focus/routine/library/detail, six logging styles with numeric entry, rest and summary; Progress/Team are starter overviews; analysis, 20 unit/widget tests, and offline iOS entrypoint/flow integration test pass; reviewed Train in light/dark | — |

### How to Resume a Session
1. Read **Current Status**, then the current phase's unchecked items.
2. Work one checkbox at a time; check it off (`[x]`) in the same commit as the code.
3. When all items in a phase pass its **Exit Criteria**, advance **Current phase**.
4. New product decisions go in **Resolved Decisions** (bottom); never silently change a locked decision.
5. Before ending: update **Current Status** + add a **Session Log** row.

### Prerequisites (Before Phase 1)
- [x] Flutter SDK (stable) + Firebase CLI installed and logged in
- [x] FlutterFire CLI 1.4.1 (`~/.pub-cache/bin` must be on `PATH`)
- [x] Xcode 26.6 + CocoaPods 1.16.2; Android Studio + SDK 36 (`flutter doctor` clean)
- [x] Node **24 LTS** (Homebrew `node@24`, v24.21.0) for Cloud Functions; set `"engines": {"node": "24"}` in `functions/package.json`
- [x] Bundle/application ID: `com.howtohockey.app`
- [x] Apple Developer Program account
- [ ] App Store Connect app record for `com.howtohockey.app` (deferred: needed before Phase 8 IAP / first TestFlight)
- [x] Google Play Console account
- [ ] Play Console app record for `com.howtohockey.app` (deferred: needed before Phase 8 IAP / first internal test)
- [x] Firebase project `how-to-hockey` on the **Blaze** plan
- [ ] RevenueCat account (needed by Phase 8; can wait)

---

## 0. Architecture Decisions (Locked Before Coding)

| Concern | Choice | Reason |
|---|---|---|
| Platforms | iOS + Android only (no web/desktop folders) | Spec scope |
| Flutter | Latest stable, Dart 3, null-safe, Material 3 + custom theme | |
| State management | `flutter_riverpod` (+ `riverpod_generator`) | Testable, scoped providers for session engine |
| Routing | `go_router` with auth/role/entitlement redirects | Deep links for team invites |
| Models | `freezed` + `json_serializable` | Immutable models, Firestore (de)serialization |
| Backend | Firebase: Auth, Firestore, Cloud Functions (TypeScript, 2nd gen), Storage, FCM, Remote Config, Analytics, Crashlytics, App Check | |
| Payments | RevenueCat (`purchases_flutter`) + webhook → Cloud Function → Firestore/custom claims | Handles subs, one-time IAP, intro/discount offers, cross-platform entitlements |
| Charts | `fl_chart` (Radar chart, bar/line charts) | |
| Motion | `animations` (shared axis, fade through, container transform) + implicit animations | Fluid, consistent transitions (see §3) |
| Media | Looping MP4 (H.264, muted, 3–5s) via `video_player` + `flutter_cache_manager`; long-form as progressive MP4 streamed from Firebase Storage via short-lived signed URLs | MP4 is far smaller than GIF; long-form volume is small, so no separate video provider |
| Audio | `just_audio` (chimes) + `audio_session` (mix with user's music) | |
| Wake/haptics | `wakelock_plus`, `HapticFeedback` | Screen stays on during sessions |
| Sharing | `RepaintBoundary` → PNG → `share_plus` | Native share sheet only |
| Local persistence | Firestore offline cache + `shared_preferences` for setup/focus presets | Garage/rink often has bad signal |
| Environments | Single Firebase project `how-to-hockey`, single app ID `com.howtohockey.app`; no flavors. Local development runs against the **Firebase Emulator Suite**; real-device testing hits production with test accounts flagged `isTester` (excluded from leaderboards/analytics) | Simplicity; emulators keep test data out of prod |
| CI/CD | GitHub Actions (analyze, test, build) + Fastlane / Codemagic for store uploads | |

### Guiding Principles
- **Server is source of truth for anything social, competitive, or paid.** Feed posts, leaderboards, PRs, lifetime totals, entitlements, and verification badges are written only by Cloud Functions.
- **No UGC.** No free-text, photo, or video upload fields anywhere a player can reach. Display names are picked from first name + last initial, validated server-side.
- **Offline-first sessions.** An active session must never fail due to connectivity.
- **Timers use wall-clock timestamps**, not tick counting, so backgrounding/locking the phone does not corrupt durations.

---

## 1. Project Structure

```
lib/
  main.dart            # `--dart-define=USE_EMULATORS=true` for local dev
  app/                 # App widget, router, role shells (player/parent/coach)
  design/              # tokens (color, type, spacing, radius, motion), ThemeData light/dark, ThemeExtensions
  core/                # constants, utils, extensions, error types
  data/
    models/            # freezed models (Drill, Routine, Session, SetLog, ...)
    repositories/      # Firestore/RevenueCat-backed repos (interfaces + impls)
  features/
    auth/
    onboarding/        # setup parameters + focus scale
    smart_coach/       # routine generation engine (pure Dart)
    library/           # drill browser + filters
    session/           # active training engine
    progress/          # radar, PR vault, lifetime totals
    team/              # locker room, leaderboards, stick taps
    coach/             # roster, routine builder, assignments, compliance
    parent/            # child profiles, verification
    paywall/           # tiers, offerings, signature programs
    share/             # share card rendering
  shared/widgets/      # design-system components (StatTile, MetricCard, NumberPad, Stepper, TimerRing, ...)
functions/             # Cloud Functions (TypeScript)
firestore.rules
storage.rules
firestore.indexes.json
test/ integration_test/
tool/seed/             # drill catalog seed scripts
```

---

## 2. Expanded Data Model

The spec's `Drill` is the starting point. Additions are required to generate and run routines.

```dart
enum TrackingType { volume, duration, density, accuracy, streak, binary }
enum LocationOption { ice, roller, drivewayGarage, basement, syntheticIce }
enum PuckInventory { low, medium, high } // 1-10, 10-25, 25+
enum BallType { golfBall, trainingBall, greenBiscuit }
enum PasserType { rebounder, partner }
enum SkillPillar { shooting, stickhandling, skating, passing, iqConditioning }
enum AccessTier { free, pro }

class Drill {
  // --- From spec ---
  final String id;
  final String title;
  final String mediaAssetPath;
  final List<String> formCues;              // max 3
  final TrackingType trackingType;
  final List<LocationOption> allowedLocations;
  final PuckInventory minPuckInventory;
  final bool requiresPasser;
  final Map<SkillPillar, double> skillWeights; // sums to 1.0
  // --- Additions ---
  final AccessTier tier;                    // 20 drills = free starter set
  final List<BallType> supportedBalls;      // off-ice substitute for pucks
  final List<PasserType> passerTypes;       // which passer satisfies requirement
  final DrillPrescription defaultPrescription; // sets, reps, seconds, targetLabel
  final int estimatedSecondsPerSet;
  final int difficulty;                     // 1-5
  final List<String> tags;                  // 'quick-release', 'toe-drag', ...
  final String? swapGroup;                  // drills interchangeable for "Swap Drill"
}

class DrillPrescription {
  final int sets;
  final int? reps;          // volume, accuracy (total shots)
  final int? seconds;       // duration, density window
  final int restSeconds;    // default 45
  final String? targetLabel;// accuracy: "Top-right pipe"
}

class SetLog {
  final int setIndex;
  final int? reps;          // volume / density count / accuracy total
  final int? hits;          // accuracy
  final int? seconds;       // duration actual
  final int? streak;        // streak
  final bool? completed;    // binary
  final DateTime loggedAt;
}
```

### Firestore Collections

```
users/{uid}                       roles[] (player|parent|coach), email, createdAt, lastMode
                                  (active profile is stored per device, never on the account)
  entitlements (read-only to client; written by Functions)
profiles/{profileId}              ownerUid, displayName, birthYear, isChild, teamIds[],
                                  teamProGrant {teamId, expiresAt} (written by Functions, once per profile; never shared)
  /sessions/{sessionId}           routine snapshot, setup, focus, startedAt, endedAt, status, activeSeconds,
                                  groupSessionId? (siblings training together on one device)
    /drills/{idx}                 drillId + SetLog[]
  /stats/lifetime                 totalShots, activeSeconds, routinesCompleted, pillarSeconds{}
  /prs/{prKey}                    value, sessionId, achievedAt
  /focusPresets/{id}
drills/{drillId}                  catalog (pro drills' media gated by Storage rules)
routines/{routineId}              official or coach-authored (ownerUid, teamId?)
programs/{programId}              signature programs; /days/{n}
teams/{teamId}                    name, searchName, visibility (private|public), coachUids[],
                                  joinCode, coachPro (bool), memberCount
  /members/{profileId}            joinedAt, addedByUid (parent uid for child profiles)
  /joinRequests/{profileId}       pending requests for public-team discovery / kid-device requests
  /feed/{postId}                  system-generated; /taps/{profileId}
  /assignments/{assignmentId}     routineId, dueAt, assignedProfileIds[]
    /completions/{profileId}
  /leaderboards/{period}          materialized by Functions
teamDirectory/{teamId}            public teams only: name, coach display name, memberCount,
                                  generic stats (weekly team hours, sessions); written by Functions
parentLinks/{uid}                 childProfileIds[] (max 3)
```

---

## 3. Design System & Brand

### 3A. Look & Feel
Modern, calm, data-forward, in the style of **MacroFactor Workouts** but with How To Hockey branding:
- **Content first, low chrome:** mostly neutral surfaces with a **single brand accent (red)** reserved for primary actions, active state, and progress. No gradients, heavy shadows, or decorative clutter.
- **Big, confident numbers:** stats, timers, and set inputs are the hero of each screen (large tabular numerals, small muted labels).
- **Card-based layouts** with generous spacing; information density increases only in analytics/coach views.
- **One-handed, glove-friendly:** primary actions in the bottom thumb zone; minimum 48dp touch targets, 56–64dp for in-session controls.
- **Hockey identity through details**, not ornament: How To Hockey logo/wordmark, subtle ice/rink line motifs on empty states and share cards, Coach Jeremy media front and center.

### 3B. Brand Color & Palette
> Brand primary is **`#CC3333`**, matching the logo SVG.

| Token | Light | Dark | Notes |
|---|---|---|---|
| `brand/primary` | `#CC3333` | `#CC3333` | Buttons/fills. White text on it ≈ 5.1:1 (AA) |
| `brand/primaryOnDark` | — | `#E05555` | Red text/icons on dark surfaces (≈5.1:1); `#CC3333` on near-black is only ≈3.7:1 and fails AA for small text |
| `brand/primaryContainer` | `#FAE6E6` | `#3A1616` | Selected chips, highlights |
| `brand/cream` | — | `#F7F4E7` | From the white logo; logo on red/dark, share-card text, splash on dark |
| `bg` | `#FFFFFF` | `#0E0E10` | Not pure black, to avoid OLED smearing on scroll |
| `surface` | `#F5F5F7` | `#1A1A1D` | Cards |
| `surfaceElevated` | `#FFFFFF` + hairline border | `#232327` | Sheets/dialogs; dark mode uses lighter surfaces instead of shadows |
| `textPrimary` / `textSecondary` | `#111114` / `#6B6B73` | `#F5F5F7` / `#9A9AA3` | |
| `success` | `#1E9E5A` | `#3CCB7F` | Completed sets, PRs |
| `warning` | `#D98E04` | `#F2B233` | |
| `error` | `#B3261E` + icon | `#FF6B6B` + icon | Always paired with an icon/label so it's never confused with the brand red |

- **Pillar colors** (radar, charts, tags): five distinct, colorblind-checked hues tuned to sit next to the brand red (e.g., Shooting = brand red, Stickhandling = blue, Skating = teal, Passing = amber, IQ/Conditioning = violet). Validate with a CVD simulator.
- Generate `ColorScheme` manually from tokens (not `fromSeed`) so the exact brand red is preserved.

### 3C. Typography
- Primary font: **Inter** (variable, v4+, SIL OFL). It's modern, neutral, very legible at small sizes, and has true tabular figures. Use its optical-size axis (`opsz`) so large numerals and titles automatically get the tighter "Display" cut.
  - Bundle locally in `assets/fonts/` (no runtime `google_fonts` fetching, since sessions must work offline); register the OFL license with `LicenseRegistry`
  - Weights used: 400 (body), 500 (labels), 600 (titles), 700/800 (hero numerals, headlines)
  - Tabular figures (`FontFeature.tabularFigures()`) for all numbers/timers so digits don't jitter
  - Slightly tightened letter-spacing on Display/Headline sizes, default on body
- Scale: Display (timers/hero stats) · Headline (screen titles) · Title (cards) · Body · Label (muted caps for metric labels).
- Respect OS text scaling up to 200%; hero numerals scale with a cap so layouts don't break.

### 3D. Shape, Spacing, Elevation
- 4pt spacing grid; screen padding 20; card padding 16.
- Radii: cards 20, buttons 14, chips/fields 12, sheets 28 (top corners).
- Flat by default; elevation expressed by surface tone, plus a hairline border in light mode.

### 3E. Motion & Navigation
- **Navigation structure:** bottom nav per role shell with preserved tab state (`StatefulShellRoute`), large collapsing titles (`SliverAppBar.large`), modal bottom sheets for quick inputs/filters, full-screen immersive mode for active sessions.
- **Transitions:** fade-through between tabs; shared-axis (horizontal) for drill-to-drill in a session; container transform from a routine/drill card into its detail; Hero for drill media.
- **Durations/curves:** 150ms micro, 250–300ms standard, 400ms large; Material 3 emphasized easing. Token-driven via a `MotionTokens` ThemeExtension.
- **Micro-interactions:** animated number counters on stat changes, progress ring fills, spring-y stepper taps, confetti-lite PR celebration (brief, skippable).
- **Haptics:** light on stepper/selection, medium on Log Set, success pattern on session complete/PR.
- **Platform feel:** iOS edge swipe-back and Android predictive back both supported; one shared visual language on both platforms.
- Honor **Reduce Motion** (`MediaQuery.disableAnimations`): swap transitions to fades, disable counters/confetti.

### 3F. Light & Dark Themes
- `ThemeMode.system` by default; in-app **Appearance** setting (System / Light / Dark) in Me/Account, persisted per device (`shared_preferences`) and applied before first frame (no flash).
- Both themes built from the same tokens; every component and screen must be designed and reviewed in both.
- Coach Jeremy media and share cards: share cards always render in a fixed branded style regardless of theme.
- Status bar/navigation bar icon brightness follows the active theme (`SystemUiOverlayStyle`).

### 3G. Key Screen Patterns
- **Train home:** today's suggestion card (large), quick-start setup chips (location/pucks), saved routines carousel, streak + weekly time ring.
- **Active session:** dark-leaning immersive layout in both themes, media card top, huge input/timer center, sticky action bar bottom; minimal text.
- **Rest timer:** full-width ring countdown with `−15s` / `+15s` / `Skip` as large pill buttons.
- **Progress:** radar hero, PR Vault as a clean list of metric cards, lifetime totals as big-number tiles.
- **Locker Room:** compact system-post cards with stick-tap button and verified badge; no input fields.
- **Coach/Parent:** table-like dense lists with filter chips; same tokens, higher density.

### 3H. Brand Assets & Usage
Provided in `assets/`: maple-leaf "HTH" monogram (≈square, viewBox 1307×1251) and "How To Hockey" wordmark PNGs.

| File | Color | Use |
|---|---|---|
| `logo-red.svg` / `.png` | `#CC3333` | Light theme headers, auth screens, splash (light), share cards on light |
| `logo-white.svg` / `.png` | `#F7F4E7` (cream) | Dark theme, on brand-red backgrounds, splash (dark), app icon foreground, Android themed (monochrome) icon |
| `HTH_TEXT_ONLY.png` | White on transparent, 1394×187 | "How To Hockey" wordmark: auth/welcome screen, Train home header, paywall, share-card footer |
| `HTH_LOGO_WHITE_LARGE.png` | White on transparent, 2000×2000 | High-res source for app icon/splash generation and share cards |

- [ ] Move to `assets/brand/` inside the Flutter project; render SVGs with `flutter_svg`; keep PNGs only as `flutter_launcher_icons` / `flutter_native_splash` sources (export at ≥1024px)
- [x] **App icon (iOS):** cream mark centered on solid brand-red square (no transparency allowed), ~70% scale; verify the thin maple outline stays legible at 29–40pt
- [x] **App icon (Android adaptive):** background = brand red; foreground = cream mark inside the 66% safe zone; monochrome layer from `logo-white.svg`
- [x] **Native splash:** light = `#FFFFFF` + red mark; dark = `#0E0E10` + red mark (or cream); Android 12+ splash icon sized to its circular mask
- [ ] `BrandLogo` widget that picks the variant from the active theme (red on light, cream on dark/red)
- [ ] `BrandWordmark` widget: the wordmark is single-color with alpha, so tint at runtime with `Image.asset(color:, colorBlendMode: BlendMode.srcIn)` (textPrimary/red on light, cream on dark/red) instead of shipping per-theme PNGs
- [ ] Wordmark max display width ≈ 300pt so the 1394px source stays sharp at 3×; request an SVG version for larger uses
- [ ] Clear space around the mark ≥ ¼ of its width; minimum in-app size 24dp
- [ ] Small-size check: if the outline/monogram blurs below ~32px, request a simplified glyph for tiny sizes (notification icon, favicon-like uses)
- [ ] Android notification small icon: single-color white silhouette derived from the mark

### 3I. Design Deliverables & Tooling
- [x] Logo mark (SVG + PNG, red and cream variants)
- [x] "How To Hockey" wordmark (PNG) and large white logo (PNG)
- [x] Font: Inter (variable)
- [x] Primary color confirmed: `#CC3333`
- [ ] Nice-to-have: wordmark as SVG
- [ ] Optional Figma companion: Flutter is the approved design-review source of truth during UX Preview; a Figma file is no longer a prerequisite for UI work
- [x] Design tokens mirrored in `lib/design/` (single source; no hard-coded colors/sizes in features)
- [ ] `widgetbook` catalog of design-system components with a light/dark toggle
- [ ] Golden tests per component in light and dark, plus large text scale
- [ ] Lint rule/review check: no raw `Color(...)`/`TextStyle(...)` outside `lib/design/`

---

## Phase 1 — Foundations
- [x] Create the Flutter app **at the repo root**: `flutter create --project-name how_to_hockey --org com.howtohockey --platforms=ios,android .`; move existing `assets/*` into `assets/brand/`
- [x] Run `flutterfire configure --project=how-to-hockey` (iOS + Android only)
- [x] `USE_EMULATORS` dart-define wires Auth/Firestore/Functions/Storage to local emulators; VS Code launch configs for "Emulators" and "Live"
- [x] Firebase **Anonymous Auth** so Phases 2–3 can persist data before real accounts; Phase 4 links anonymous users to real credentials without data loss
  - [x] Sign in anonymously at startup when no user is already signed in, after emulator routing is configured
  - [x] Enable the Anonymous provider in Firebase Console for `how-to-hockey`
- [x] Install core packages (Riverpod, go_router, freezed, Firebase SDKs)
- [x] Wire Crashlytics error reporting, Analytics collection, and App Check (debug providers for development; App Attest/DeviceCheck + Play Integrity for production)
- [x] Provision the live Firestore default database and Firebase Storage bucket in Toronto; enable delete protection for Firestore and deploy deny-by-default rules
- [ ] Register production App Check providers (Play Integrity and Apple App Attest/DeviceCheck) and verify production attestation on real devices; Android development debug token is registered (remaining production setup deferred until release preparation; not a local-development gate)
  - [x] Register Apple Team ID `A3T2KUV3B5` and configure App Attest in live Firebase with the default one-hour token TTL
  - [x] Add the production App Attest entitlement and wire it into all iOS build configurations
  - [x] Wire private Android upload-key configuration; release builds fail explicitly when signing configuration is missing instead of using the debug key
  - [ ] Create/link the Play Console app to Firebase project `how-to-hockey` and register the Play app-signing certificate SHA-256
  - [ ] Configure DeviceCheck fallback in Firebase using an Apple DeviceCheck-enabled key; never commit the private key
  - [ ] Verify valid production App Check tokens on Android and iOS before enabling enforcement
    - [x] Verify a fresh App Attest token on a signed physical iPhone
    - [ ] Verify DeviceCheck directly on a physical iPhone
    - [ ] Verify Play Integrity on the Play-installed Android app
- [x] Set up Firebase Emulator Suite (Auth, Firestore, Functions, Storage) for local dev; Firestore and Storage emulators use deny-by-default rules
- [x] `functions/` TypeScript project with ESLint and unit tests
- [x] Design system foundation per §3: tokens, light/dark `ThemeData`, `ThemeExtension`s (pillar colors, motion), bundled Inter variable font, Appearance setting (System/Light/Dark)
- [x] App icon + splash per §3H via `flutter_launcher_icons` and `flutter_native_splash`; native splash matches first frame
- [x] CI: `flutter analyze`, `flutter test`, functions tests, rules tests on every PR
  - [x] Verify a green GitHub Actions run before advancing to Phase 2

**Exit Criteria:** [x] App boots on both platforms against emulators; CI green.

---

## Phase 2 — Drill Catalog & Content Pipeline
- [x] Implement models in §2 with freezed + converters
- [x] Define drill spreadsheet/JSON schema; write `tool/seed/` script to upload drills to Firestore and media to Storage
- [ ] Media spec: 3–5s MP4, 720p, muted, ≤1.5 MB, plus poster JPG
- [ ] Seed the **20 free starter drills** covering all 5 pillars and all 6 tracking types
- [ ] Drill Library screen: list, detail, looping media card, form cues
- [ ] Filters: location, puck inventory, ball type, passer, pillar, tracking type (filters are Pro-only per tier matrix; free sees the starter 20)
- [ ] Media caching and preloading of the next drill's video

**Exit Criteria:** All seed drills browsable offline after first load.

---

## UX Preview — Design Before Backend (Current Priority)
Approved 2026-10-05: pause scheduled backend/content work and review the complete intended UX directly in Flutter with local placeholder data and media. Existing architecture, design tokens, tier rules, separate role shells, and no-UGC constraints stay locked.

Preview mode is explicitly opt-in, does not initialize Firebase, and does not perform real authentication, purchases, uploads, or server writes. Interactive local state is for reviewing UX, not a substitute for the production session engine or backend acceptance criteria. Use bundled/illustrated placeholders, not remote image services. Keep existing Live/Emulators launches working.

Work these slices in order, reviewing the visual direction between slices:
- [x] Isolated preview launch, local fixtures, shared branded components, and preserved Player tab navigation
- [x] Player training: Train home → setup/focus → routine preview → all six set-input types → rest → summary; drill library/detail and manual logger entry points
- [ ] Player progress: radar, PR Vault, lifetime totals, session history/detail, share-card preview
- [ ] Player team: locker room, stick taps, leaderboards, homework, invite/join/discovery, member-only/empty/locked states
- [ ] Player Me: appearance, profile switching, role switcher, account/subscription entry points
- [ ] Parent shell: Kids, child detail/controls, Verify, Account, kid-device pairing, join approvals, Train Together
- [ ] Coach shell: Roster, Homework/builder/assignment, Compliance, Team settings/invites/verification
- [ ] Welcome/signup/age gate, role onboarding, paywalls/restore/manage, program storefront/detail/day/lesson
- [ ] Review every screen in light/dark, 200% text scale, small phone sizes, and Reduce Motion; include loading/empty/error/locked states where applicable
- [ ] User approval of screen inventory, navigation, visual design, and core flows before resuming backend/content milestones

**Exit Criteria:** All planned screens are navigable with representative local fixtures and clearly labeled simulated actions; user approves the UX direction. Production roadmap checkboxes stay unchecked unless their original functional criteria are independently met.

---

## Phase 3 — Active Training Engine (Core Loop Step 2)
Build as a pure-Dart `SessionController` (Riverpod Notifier) with a thin UI on top so it is unit-testable.

- [ ] Session state machine: `notStarted → drillActive → resting → drillActive … → summary`
- [ ] Top bar: "Drill X of N" + overall timer (wall-clock based)
- [ ] Media card with looping demo + 3 form cues
- [ ] Dynamic Input Module, one widget per `TrackingType`:
  - [ ] **Volume:** stepper + direct numeric entry per set
  - [ ] **Duration:** countdown with start/stop chimes, 3-2-1 lead-in
  - [ ] **Density:** timer → numeric pad → computes SPM = `reps / seconds * 60`
  - [ ] **Accuracy:** hits / total → accuracy %; validate `hits ≤ total`
  - [ ] **Streak:** single numeric entry for max consecutive
  - [ ] **Binary:** large toggle per set
- [ ] Action bar: `Log Set`, `Swap Drill` (same `swapGroup`, still matching setup), `Rest Timer`
- [ ] Rest mechanics: auto-start after Log Set (default 45s), `+15s`, `-15s`, `Skip Rest`; chime + haptic on end
- [ ] Local notification when rest ends while app is backgrounded
- [ ] Wakelock on during session; audio session mixes with user's music
- [ ] Persist session progress after every set (resume after app kill)
- [ ] Session summary screen with totals per drill
- [ ] **Manual loggers (free tier):** standalone Shot Logger and Timer without a routine
- [ ] Unit tests for every tracking type's calculations and the state machine

**Exit Criteria:** A hard-coded routine can be run end to end, killed mid-session, resumed, and saved.

---

## Phase 4 — Accounts & Profiles
- [ ] Firebase Auth: Sign in with Apple (required on iOS when offering third-party login), Google, email/password; `linkWithCredential` upgrades the Phase 1 anonymous user
- [ ] Age gate at signup (birth year). Under-13 users cannot create an account; they must be created as a **child profile by a parent** (COPPA / GDPR-K)
- [ ] `users` / `profiles` split: one account can own multiple player profiles
- [ ] **Any account tier (including Free)** can create and manage child player profiles (cap: 3, enforced in a callable Function)
- [ ] Display name restricted to first name + last initial; server-side validation
- [ ] **Kid device sign-in:** parent generates a short-lived QR/code → Function mints a custom token with a `profileId` claim → device is locked to Player mode for that child only (no parent, billing, or account-deletion access)
- [ ] **Shared device alternative:** on the parent's device, Player mode has a "Switch Player" picker for the parent's child profiles (optionally PIN-protected exit back to Parent/Coach mode)
- [ ] Active profile is device-local state, so several devices on one account can run different profiles at the same time
- [ ] Account deletion flow in-app (required by both stores) → Function cascades data deletion
- [ ] Firestore rules: a user can only read/write their own profiles' private data

### 4B. Role-Based App Modes (Separate Shells)
An account can hold multiple roles (e.g., a coach who is also a parent). Each role gets its own navigation shell; a mode switcher in the account menu moves between them. Screens never mix concerns across roles.

| Mode | Bottom nav | Owns |
|---|---|---|
| **Player** | Train · Progress · Team · Me | Sessions, routines, radar/PRs, locker room, stick taps, homework. Bound to one active profile. |
| **Parent** | Kids · Verify · Account | Child profiles CRUD, each child's teams/invites/requests, workout verification, leaderboard visibility, subscription/billing |
| **Coach** | Roster · Homework · Compliance · Team | Team settings (visibility, join code), roster approvals, routine builder, assignments, compliance dashboard, verification |

- [ ] `go_router` `StatefulShellRoute` per mode; redirect guards by role + active profile
- [ ] Parent "Train as [Child]" shortcut jumps into Player mode for that child profile
- [ ] Kid-device sessions only ever see Player mode
- [ ] Widget tests asserting each shell exposes only its own routes

**Exit Criteria:** Rules tests pass for owner/non-owner access; deletion removes all data.

---

## Phase 5 — Onboarding & Smart Coach Engine (Core Loop Step 1)
### 5A. Setup Parameters UI
- [ ] Location picker (5 options)
- [ ] Puck inventory (single select: Low/Medium/High)
- [ ] Off-ice ball optional toggle (Golf Ball / Training Ball / Green Biscuit)
- [ ] Passer optional toggle (Rebounder / Partner)
- [ ] Remember last setup; allow saved presets ("Garage", "Rink Tuesday")

### 5B. 100-Point Focus Scale
- [ ] Five sliders and/or interactive radar
- [ ] Zero-sum rebalance algorithm: when pillar *i* changes by Δ, distribute −Δ across the other pillars **proportionally to their current values**; if all others are 0, distribute evenly; clamp to [0,100]
- [ ] Integer rounding via largest-remainder method so the total is always exactly 100
- [ ] Unit tests: sum invariant, clamping, all-zero edge case

### 5C. Generation Algorithm (pure Dart, runs on-device)
1. **Hard filters:** `allowedLocations ∋ location`; `minPuckInventory ≤ inventory` (off-ice ball counts as satisfying inventory if drill supports it); `requiresPasser → passer present & type matches`; tier access.
2. **Score:** `score(d) = Σ focus[p] / 100 × d.skillWeights[p]` (+ small random jitter, − penalty if done in last N sessions).
3. **Allocate slots:** target session length (e.g., 20/30/45 min) → number of drills; allocate slots per pillar proportional to focus points (largest remainder).
4. **Select:** highest scoring per pillar slot, enforcing tracking-type variety and no duplicate `swapGroup`.
5. **Puck-inventory shaping:** Low → prefer single-puck / reset-and-retrieve and add retrieval time to estimates; High → allow density drills.
6. **Order:** warm-up (stickhandling/skating, low difficulty) → high-intensity shooting/density → finisher (streak/IQ).
7. **Prescribe:** use `defaultPrescription`, scaled by difficulty and recent performance.
- [ ] Deterministic seed option for tests
- [ ] Golden tests for known setups → expected routine
- [ ] Free tier can generate custom routines (from the 20 starter drills) but may keep **max 3 saved routines** per profile; Player Pro = unlimited saves + full 100+ drill pool
- [ ] Enforce the saved-routine cap server-side: `createSavedRoutine` callable Function checks entitlement + count (rules can't count docs); client shows "replace a saved routine" prompt when at cap
- [ ] Downgrade handling: if Pro lapses with >3 saved, keep all readable but block new saves until ≤3

**Exit Criteria:** User picks setup + focus → receives a valid routine → runs it in the Phase 3 engine.

---

## Phase 6 — Analytics & Progression (Core Loop Step 3)
- [ ] Cloud Function `onSessionCompleted` (Firestore trigger):
  - [ ] Validate set logs (sane ranges; reject impossible values, e.g., >5 shots/sec)
  - [ ] Compute **active training seconds** (the shared unit for radar and leaderboards):
    - duration/density sets → timed seconds actually run
    - volume/accuracy/streak/binary sets → drill's `estimatedSecondsPerSet`
    - rest time excluded; per-session and per-day caps (Remote Config, e.g., 4h/day) to block idle-timer gaming
  - [ ] Update `stats/lifetime` (shots, activeSeconds, routines, `pillarSeconds[p] += setSeconds × skillWeights[p]`)
  - [ ] Evaluate PRs per metric key (e.g., `accuracy_10shot_pct`, `density_30s_shots`, `streak_juggle`)
  - [ ] Compute daily streak
- [ ] **Skill Radar** (decision: absolute levels on training time):
  - Each pillar has Levels 1–10 from cumulative `pillarSeconds`; thresholds grow geometrically (e.g., L1 = 1h, ×1.65 per level → L10 ≈ 90h), tunable in Remote Config
  - Vertex = `level + progressToNext` so it visibly grows every session and never shrinks
  - Time (not reps) is used because reps are not comparable across tracking types (a juggle streak ≠ a slap shot ≠ a footwork set)
  - Faint overlay polygon shows the player's current 100-point focus allocation (plan vs. actual work)
  - Tap a vertex → level, hours, top drills for that pillar
- [ ] **PR Vault:** categorized by metric type, with date and link to session
- [ ] **Lifetime Totals:** shots, hours, routines completed
- [ ] Session history list + per-drill breakdown charts (Pro)
- [ ] Gate: free sees lifetime totals; Radar, PR Vault, breakdowns are Player Pro

**Exit Criteria:** Completing a session updates totals, radar, and PRs within seconds.

---

## Phase 7 — Native Share Cards
- [ ] Branded card widget (session stats, streak, PR badges) rendered offscreen at 1080×1920 and 1080×1080
- [ ] `RepaintBoundary.toImage` → PNG → `share_plus` share sheet
- [ ] No upload to servers; nothing stored remotely

---

## Phase 8 — Monetization
- [ ] App Store Connect / Play Console products:
  - Player Pro: monthly $7.99, yearly $49.99
  - Coach Pro: monthly $12.99, yearly $99.99
  - Signature Programs: non-consumable IAPs $14.99–$39.99, plus discounted variants (−20%) for Pro subscribers
- [ ] RevenueCat: entitlements `player_pro`, `coach_pro`, `program_<id>`; offerings for paywalls
- [ ] RevenueCat webhook → Cloud Function → write `users/{uid}.entitlements` + custom claims
- [ ] Firestore/Storage rules read entitlements (Pro drill media, Pro analytics endpoints)
- [ ] **Effective Pro for a profile** = owner account has `player_pro` or `coach_pro` **OR** `profile.teamProGrant.expiresAt > now` **for that profile only** (a grant never extends to the owner account or sibling profiles); single resolver shared by client (UI gating) and rules/Functions (enforcement)
- [ ] Paywall screens with feature comparison; restore purchases; manage subscription link
- [ ] Program discount: show discounted product ID only when `player_pro` is active
- [ ] `coach_pro` entitlement **includes all `player_pro` features** (configure in RevenueCat: Coach Pro products grant both entitlements)
- [ ] Sandbox/test-track purchase testing on both platforms

**Exit Criteria:** Purchasing unlocks features on both platforms; cancel/expire revokes them.

---

## Phase 9 — Teams & Locker Room Feed
- [ ] Create team (Coach mode) → join code + deep link invite; visibility **private** (default) or **public**
- [ ] **Membership is per player profile**, never per account. A parent can place each child on the same or different teams; one child can be on multiple teams
- [ ] Join flow: open invite/code → choose which profile joins (own profile or a child) → joined
  - From a kid device → creates a `joinRequest` the parent must approve in Parent mode
- [ ] **Public team discovery:** prefix search over `teamDirectory`; card shows team name, coach display name, player count, and generic team stats (e.g., weekly team training hours, sessions) → "Request to Join" → coach approves
- [ ] `teamDirectory/{teamId}` is a separate doc maintained by Functions (Firestore rules can't hide individual fields, so the private `teams` doc is never publicly readable); removed when a team goes private
- [ ] Coaches cannot search for or invite individual players (no player directory)
- [ ] Leaving/removing: parent or coach can remove a child from a team; player data stays with the profile
- [ ] Function `onSessionCompleted` → writes system feed post:
  `[Player Name] completed [Routine] • [Key Metric] • [Streak: N Days]`
- [ ] **Stick Tap:** one per profile per post (`taps/{profileId}` doc; count via Function or `FieldValue.increment`)
- [ ] **Ranked leaderboard = active training time only** (weekly / monthly / all-time), materialized by Function from `activeSeconds`. Equal footing for Free, Pro, and program owners, and it can't be inflated by idle timers (see Phase 6 caps)
- [ ] Non-ranked team stats shown alongside (total team shots, sessions, longest streak) for flavor
- [ ] Leaderboards and feed are visible **only to team members**, including on public teams (public = discoverable card only)
- [ ] Verified checkmark display on feed and leaderboard
- [ ] FCM push: stick taps received, new homework, verification
- [ ] Rules: feed/leaderboards read-only to clients except tap docs; only team members (or the parent/coach of a member) can read `teams/**`; `teamDirectory` is readable by any signed-in user
- [ ] No text inputs anywhere in team features

**Exit Criteria:** Two test accounts on one team see each other's automated posts and taps in real time.

---

## Phase 10 — Parent Linking & Verification
- [ ] Parent dashboard: manage up to 3 child profiles (available on Free; profiles created in Phase 4)
- [ ] Children inherit parent's Player Pro / Coach Pro entitlement (this is the Pro value-add for parent linking)
- [ ] "Verify Workout" action → callable Function checks caller is parent of profile or coach of team → sets `verifiedBy`, `verifiedRole` on session and feed post
- [ ] Parent controls: approve kid-device join requests, remove a child from a team, hide child from leaderboards

### 10B. Siblings Training (Apart or Together)
- [ ] **Apart:** each sibling runs their own session on their own device (kid-device sign-in) or on separate devices under the parent account; sessions are per profile, so concurrent sessions never conflict
- [ ] **Together on one device — Group Session:**
  - Start from Player mode → "Train Together" → pick 2–3 profiles from the same parent account
  - One shared routine and timer; Dynamic Input Module shows a player switcher (avatar chips) so each sibling's set is logged separately
  - Rest timer starts after all participants log the set (or when the parent taps "Next")
  - Writes one session doc per profile linked by `groupSessionId`; each sibling gets their own stats, PRs, streaks, and feed post on their own teams
  - Routine generation uses only drills **every** participant can access (e.g., one sibling on a Team Pro Month doesn't unlock Pro drills for the other)
  - Siblings present auto-satisfy the "Friend / Training Partner" passer toggle
- [ ] Tests: concurrent sessions for two profiles on one account; group session split into per-profile docs; access intersection

---

## Phase 11 — Coach Pro
- [ ] Roster management (cap 30 players, enforced in Function)
- [ ] **Team Pro Month:** when a profile joins a Coach Pro team (or an existing team upgrades to Coach Pro), Function sets `profile.teamProGrant = {teamId, expiresAt: now + 30d}`
  - **Once per profile lifetime:** joining another Coach Pro team (or leaving and rejoining) never re-grants
  - Applies **only to the rostered player profile**: never to the parent account or sibling profiles
  - Grant survives the coach cancelling; it simply expires
  - Push + in-app banner on grant and 3 days before expiry with the Player Pro paywall
  - Granted in Firestore (not RevenueCat) because it targets a profile, which may be a child under a parent's account
- [ ] Custom routine builder: pick drills, set prescriptions, reorder (drag & drop), save to team
- [ ] Assign homework: routine + due date + selected players → push notification
- [ ] Free players can complete assigned homework (assignment grants temporary access to included drills)
- [ ] **Team Compliance Dashboard:** completion % per assignment, shot volume, active minutes per player, filters by date range
- [ ] Coach verification of workouts

**Exit Criteria:** Coach assigns routine → free-tier player completes it → dashboard reflects it.

---

## Phase 12 — Signature Programs
- [ ] Program model: linear days/weeks, each day = routine + long-form lesson video
- [ ] Long-form video hosted in **Firebase Storage** (private bucket path, no public download tokens)
  - Encode offline in the seed script with ffmpeg: H.264 MP4, `+faststart`, 720p and 1080p renditions
  - Callable Function `getProgramVideoUrl` verifies the `program_<id>` entitlement → returns a V4 signed URL (short TTL, e.g., 2h)
  - `video_player` streams via HTTP range requests; client picks rendition by connection type
  - Monitor Storage egress; keep a Remote Config switch to move to a CDN later if usage grows
- [ ] Program progress tracking + "Day X of 30" UI
- [ ] Storefront with previews (trailer), price, Pro discount badge
- [ ] Launch titles: *Sniper School*, *30-Day Silky Mitts*

---

## Phase 13 — Content Scale-Up
- [ ] Film and seed the remaining 80+ drills (100+ total) with complete metadata
- [ ] Coverage audit script: every location × inventory × pillar combination yields ≥ enough drills to generate a full routine
- [ ] Remote Config for tuning generation weights without app releases

---

## Phase 14 — Hardening & Launch
- [ ] Firestore/Storage rules test suite (emulator) covering every role: player, parent, coach, non-member
- [ ] App Check enforced on Firestore, Functions, Storage
- [ ] Performance: video preloading, list virtualization, cold-start budget
- [ ] Accessibility: dynamic type, contrast (AA in both themes), VoiceOver/TalkBack labels on timers and inputs, Reduce Motion
- [ ] Design QA pass: every screen reviewed in light + dark, small + large phones, 200% text
- [ ] Integration tests for core loop (setup → generate → session → summary → feed)
- [ ] Privacy: privacy policy, App Store privacy nutrition labels, Play Data Safety form, COPPA-compliant parental consent flow
- [ ] Store category/age rating review (kids-targeted content rules for ads/analytics — no third-party ad SDKs)
- [ ] Beta: TestFlight + Play internal testing with a real team
- [ ] Production release

---

## Suggested MVP Cut
Phases **1–7** deliver the full free tier + solo core loop. Phase 8 (monetization) is the launch gate. Phases 9–11 (team/coach) can ship as v1.1 if needed; 12–13 follow content production.

---

## Resolved Decisions
- **UX-first preview:** Pause Phases 2–14 to design all planned screens in an opt-in, local-only Flutter preview with placeholder data/media. Flutter replaces the Figma-before-UI prerequisite, as approved by the user. Review Player training first, then the remaining Player, Parent/Coach, and account/commerce/program flows; resume production implementation after UX approval. *(UX Preview, 2026-10-05)*
- **Local testing priority:** Use the Samsung S24 debug launch against live Firebase with its registered App Check debug token; defer remaining production signing, Play Console, DeviceCheck, and enforcement work until release preparation. This deferred Phase 1 item does not block local development or the remaining foundation work. *(Phase 1)*
- **iOS SwiftPM Git policy:** Use an approved process-scoped `safe.bareRepository=all` exception for trusted iOS dependency builds when the machine requires explicit bare repositories; do not weaken the global Git policy or replace SwiftPM. See the build command in `README.md`. *(Phase 1)*
- **Free-tier routines:** Free users can generate custom routines but may keep only **3 saved** at a time. *(Phase 5)*
- **Coach Pro includes Player Pro.** *(Phase 8)*
- **Child profiles on Free:** Free accounts can create and manage child player profiles. *(Phases 4, 10)*
- **Team Pro Month:** Rostered players on a Coach Pro team get 30 days of Player Pro. *(Phase 11)*
- **Skill Radar:** Absolute levels per pillar based on active training time. *(Phase 6)*
- **Leaderboards:** Team-only visibility; public teams are discoverable via search. Ranked metric is active training time only. *(Phase 9)*
- **Team membership:** Per player profile; parents manage children across the same or different teams. Player, Parent, and Coach modes are separate UI shells. *(Phases 4B, 9)*
- **Long-form video:** Firebase Storage with signed URLs. *(Phase 12)*
- **Environments:** One Firebase project (`how-to-hockey`) and one app ID (`com.howtohockey.app`); emulators for local dev. *(Phase 1)*
- **Team Pro Month scope:** Once per profile ever; only the rostered player profile receives it. *(Phase 11)*
- **Public teams:** Discoverable with name, player count, and generic team stats; feed and leaderboard stay members-only. *(Phase 9)*
- **Child devices:** Kid-device QR sign-in **or** parent-device profile switching. Siblings can train concurrently on separate devices or together via Group Session. *(Phases 4, 10B)*
