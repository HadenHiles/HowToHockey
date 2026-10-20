# How To Hockey — Build Roadmap (Flutter + Firebase, iOS & Android)

This roadmap turns the product spec into ordered, checkable milestones. Each phase ends in a shippable or testable state. Work top to bottom; do not start a phase until the previous phase's **Exit Criteria** are met. The UX-first app-screen milestone below temporarily takes priority over Phases 2–14.

## 📍 Current Status
> Update this block at the end of every work session.

- **Current phase:** Phase 7 — Native Share Cards is complete. Phase 6 is complete apart from the Player Pro unlock (Phase 8); Phase 5 apart from performance-scaled prescriptions and the server-side routine cap (Phase 8 entitlement); Phase 4 apart from Sign in with Apple and Google (waiting on your console setup).
- **Next task:** Phase 8 — Monetization (RevenueCat, paywall, entitlements; also turns on the Player Pro gate and the server-side routine cap). Needs App Store Connect / Play Console products from you first. Waiting on you for Sign in with Apple and Google console setup.
- **Validation:** On 2026-10-20, `flutter analyze` passes and `flutter test test` passes all host-only tests (new: share-card data, rendering at both sizes with export to 1080×1920 and 1080×1080 PNGs, and the share flow). The cards and sheet were checked on the iPhone 16 Plus simulator; the real system share sheet was not exercised on a device.
- **Blockers:** None for the next UX slice. Phase 2 content/media and later backend integrations remain paused: workout history, real team membership/feed/standings, account-wide profile switching, and purchases are not implemented. Production App Check/release setup remains deferred; no production milestone is completed by these UI changes.
- **Last updated:** 2026-10-20

Detailed Copilot development notes live in [.github/COPILOT_REFERENCE.md](.github/COPILOT_REFERENCE.md); keep the public README focused on the app's purpose and high-level setup.

### Session Log
| Date | Summary | Commit |
|---|---|---|
| 2026-10-20 | Phase 7: share cards. A branded dark card (logo, rink markings, big number, three stats, streak, up to three personal-best badges) in two shapes, Story and Square, rendered on the phone with `RepaintBoundary.toImage` at 1080 pixels wide (1080×1920 and 1080×1080) and handed to the system share sheet with `share_plus`; the temporary file is deleted after sharing and nothing is uploaded or stored. Cards carry numbers only: no name, photo or other identity, so they are safe for child profiles. Two entry points: "Share this workout" on every workout summary, and "Share your progress" (last 7 days) on Progress, both through one preview sheet with a Story/Square switch. The card is fixed-size and ignores the phone's text size and theme so the picture always looks the same. Tests cover the card data, both renders without overflow (long names and numbers included) and the exported PNG sizes, and the share flow with failure and retry | See commit history |
| 2026-10-20 | Phase 6 finished. Tunable numbers now come from Remote Config (`remoteconfig.template.json`, deployed): shots-per-second limit, per-workout and per-day time caps, level-1 time and level growth. The app remembers the last values (so it works offline) and ignores anything out of range; the Function reads the published template (cached 5 minutes) and falls back to the defaults. Proven in production by publishing a limit and watching a probe workout count differently, then restoring. Added the per-drill breakdown (a trend line and latest/best per drill, from recent workouts) and a full workout-history list, both reachable from Progress; the breakdown is behind the Player Pro stand-in. A personal best from a workout older than the latest 60 now explains itself instead of doing nothing. Notes: Remote Config server templates are a separate store the CLI doesn't deploy, so the Function reads the published client template's default values (conditions aren't used for these settings). 317 host tests | See commit history |
| 2026-10-20 | Phase 6, cloud half. Finished workouts are written once (a single batch, session plus drill sets) under the profile that trained; rules now only accept a well-formed finished session, never an edit or delete, and refuse `processedAt`, `credit` and `rejected`, so a phone can't award itself anything. `onSessionCompleted` (Toronto, next to the database, deployed) credits each session exactly once in a transaction: it uses the catalog's own weights and times for known drills (so doctored numbers change nothing), accepts custom and manual drills within sane limits, applies the same rules, caps and levels as the app (`functions/src/progress.ts`, checked against the app by 13 shared vectors), uses the player's own time zone for days, and writes `stats/lifetime`, `prs/*` and the session's credit; unusable sessions are marked rejected and credit nothing. The app queues each finished workout for its profile (guest-era workouts are claimed by the account's own profile), retries when it can, and shows the server's stats plus anything still on its way without double counting. Found and fixed along the way: a profile screen opened right after sign-up could stay empty (reading a profile that doesn't exist yet was denied and cut the listener off; an account may now read its own profile ID early), and a previous account's profile could briefly pass as the new account's. Setup note: the first Firestore trigger needed a few minutes for Eventarc permissions to settle. 302 host tests | See commit history |
| 2026-10-20 | Phase 6, on-device half. `lib/features/progress/progress_stats.dart` (pure Dart): drops impossible sets (over 5 shots a second), active seconds per set (timed sets use the time run, others the drill estimate), per-session (3 h) and per-day (4 h) caps, skill time split by drill weights, levels 1 to 10 (1 h, then 1.65 times more each level, about 90 h at level 10), a radar point that only grows, personal bests per drill (accuracy needs 10 or more shots), daily streaks. Totals are kept as lifetime stats that survive the 60-workout history limit, saved on the device and rebuilt from history if missing or damaged. Train now shows the real weekly minutes and streak; Progress shows real all-time shots, a real week chart, the skill map with the focus plan as a faint outline and tappable levels, a personal-best vault by kind, and totals with streaks; the workout summary calls out new personal bests. Skill map and personal bests are behind a Player Pro stand-in (blurred preview plus unlock prompt) per the roadmap gate. Removed the placeholder numbers (2,480 shots, 5-day streak, 72 of 120 min). 282 host tests | See commit history |
| 2026-10-19 | Phase 5: the Smart Coach engine. Pure-Dart generator (`lib/features/coach/routine_generator.dart`): hard filters (location, pucks with a ball standing in, passer type, tier), focus-weighted scoring with a seeded nudge and a penalty for recent drills, slot quotas by largest remainder, tracking-type variety, swap groups (one per workout, a second only when a skill's quota would otherwise go unfilled, because the accuracy drills all share one group), pick-up time added for low puck counts, order warm-up then main then finishers then recovery, sets nudged to land near the chosen time (15/20/30/45 min). Setup, focus and length are remembered; named setups (max 5) can be saved and applied; the workout page, Train home and Focus page now show the generated workout with Try another and Save workout (free cap of 3 saved routines with a replace prompt). Removed the "example plan" copy. Default passer is now "training solo". Known: prescriptions are not yet scaled by recent performance, and the saved-routine cap is enforced on the device only until the server/entitlement work in Phase 8. 261 host tests | See commit history |
| 2026-10-19 | Full visual and behavior assessment from every perspective (new player, parent, kid device, coach, guest) on the iPhone 16 Plus simulator and the Android API 36 emulator, against local Auth/Firestore/Functions/Storage emulators (about 80 screens each, scripted tour, screenshots reviewed). Fixed: oversized empty header on every screen (large titles kept, now compact: title directly under a 56 pt toolbar, 40 pt on tab pages, content starts about 60 pt higher); **primary buttons hidden behind the on-screen keyboard** on every form (now pinned above it, and dragging dismisses the keyboard); a workout leaking to the next person after sign-out or kid-device pairing; stale copy ("Accounts aren't live yet", "Accounts, profiles and plans go live soon", example-data wording); truncated "Last initial" label; duplicated "Accuracy" chips and "Reps" repeated in drill lines; developer-only "Welcome & sign-up preview" shown to signed-in accounts and kid devices; Switch role now says why Parent/Coach need an account; spacing under the child-cap notice; screen sweep test used a stale child route. Known and left: Coach, Team and Progress still show clearly-labelled example data; workouts and history are saved per device, not per player, until Phase 6; the guest-to-sign-up redirect for Parent/Coach has no explanation screen. 230 host tests | See commit history |
| 2026-10-19 | Phase 4 slice 4: in-app account deletion and role route guards. `deleteAccount` Function (deployed, verified in production) removes the account, own and child profiles with their sessions, pairing codes, paired kid-device sign-ins, then the sign-in itself last so it can be retried; kid devices and guests are refused; real confirm dialog on Me and Parent. Parent and Coach screens now need a signed-in account (guests go to sign up; kid devices to Train). 227 host tests, 26 emulator function tests. Probe data deleted (one stray kid-device sign-in record from an early probe remains in Auth; harmless) | See commit history |
| 2026-10-19 | Phase 4 slice 3c: Switch player picker and Train as child are real. The active player (the account's own profile or one of its children) is saved on the device; Me shows the real name, a kid device shows its one child and can't switch. Granted the Functions service account Token Creator; production pairing then verified end to end, which exposed that a kid-device token could create profiles, so both profile Functions and the pairing Function now refuse kid devices (deployed and re-probed; probe data deleted). Workouts are still saved per device, not per player, until the Phase 6 session write. 224 host tests, 23 emulator function tests | See commit history |
| 2026-10-19 | Phase 4 slice 3b: kid-device sign-in. `createPairingCode` (parent, 8 digits, hashed at rest, 10 min, single use, replaces the child's earlier code) and `redeemPairingCode` (code to a custom token with the `profileId` claim) Functions, deployed; a real pairing screen with a live expiry countdown; a "Set up a kid's device" screen; paired devices are routed away from Parent, Coach, sign-in and paywall screens and can unpair from Me. 22 emulator function tests, 35 rules tests (pairing codes are server-only), 224 host tests. **Token minting in production needs the function service account to have Token Creator on itself** (see the reference) | See commit history |
| 2026-10-19 | Phase 4 slice 3a: the Kids screen now shows real child profiles (live Firestore list), an Add child form (first name, last initial, birth year; server-validated) and the 3-child cap message; guests are told to create an account. Approvals and Verify no longer show invented example data. Added a rules test for the parent's child query. Child-detail team and pairing actions still await their phases | See commit history |
| 2026-10-19 | Phase 4 slice 2: deployed the Firestore rules and profile Functions to production (project is on the Blaze plan; set an image cleanup policy). Built real email/password accounts: auth service with guest-to-account upgrade by linking, sign-up form (first name + last initial, email, password) that then creates the profile with a safe retry if only the profile step fails, sign-in with friendly errors and an enumeration-safe password reset, and real account sheets on Me and Parent. Verified end to end against local Auth/Firestore/Functions emulators on Android; 218 host tests pass. Apple and Google sign-in still need console setup | See commit history |
| 2026-10-16 | Phase 4 slice 1: data model and server. Added `createChildProfile` and `createOwnProfile` Cloud Functions (name and birth-year validation, non-anonymous accounts only, transactional 3-child cap, certain-minor/certain-13+ age reading), Firestore rules for users/profiles/private profile data including kid-device tokens locked to one profile, Dart models/validation/repository, and shared name test vectors used by both TypeScript and Dart. Tests: 30 function unit tests, 14 Firestore-emulator tests (incl. a simultaneous-request race), 33 rules tests, 204 Dart tests. CI now runs the emulator tests. Nothing deployed to production | See commit history |
| 2026-10-16 | Per the user's choice, closed Phase 3's 'saved' gap with a local on-device workout history: finished workouts are saved when finished (latest 60), Progress shows real totals and recent training, and any workout opens in the same summary view; corrupt entries are skipped and reported. 170 host tests pass; checked on both emulators. Starting Phase 4 | See commit history |
| 2026-10-16 | Phase 3: replaced the placeholder Shot logger/Timer buttons with real manual loggers (shots with optional hits; timer from 30 s to 20 min) that flow through the saved session and summary, with a confirm-before-replacing-a-workout guard; fixed a text-controller disposal bug in the number dialog found by tests; kept the drill demo behind the Drill details button per the user. 156 host tests pass; checked on both emulators. Phase 3 build items are done; the exit criterion's cloud "saved" is deferred to Phase 4/6 | See commit history |
| 2026-10-16 | Phase 3: per-drill totals and per-set derived numbers on the summary (new `set_summary.dart`, tested); Swap Drill (same swap group, fits the setup, only before sets are logged) and a manual Start rest on the workout card, with notifier methods and tests including a 320 px / 200% text fit check; corrected two stale 'until you close the app' lines now that workouts are saved. Visually verified on both emulators (one-at-a-time runs, since two simulators plus builds caused memory-pressure ANRs) | See commit history |
| 2026-10-16 | Phase 3 rest reminders: added a local notification when a rest ends while backgrounded (scheduled on leaving the app, cancelled on return, permission asked once at the first rest, Me switch, stopwatch status icon, Android desugaring and receiver setup) with 9 tests. The in-app rest chime now stays quiet in the background to avoid doubling. Verified on the Android emulator end to end; iOS scheduling could not be verified in the simulator | See commit history |
| 2026-10-16 | Phase 3 cues: added a wall-clock `SetCountdown` (3-2-1 lead-in, pause/resume/cancel) with 10 unit tests, four original synthesized tones, haptics, rest-end chime, and a saved Sounds and haptics setting on Me. Session timing now uses the injectable clock so widget tests can fake time. Device runs caught two real bugs, both fixed: iOS rejects the generic mix-with-music plus respect-silent audio flags (now an explicit ambient session) and low-latency audio mode keeps a frame callback running (now the normal mode). 121 host tests pass | See commit history |
| 2026-10-16 | Phase 3 start: added shared tracking-type calculations and entry validation (`set_calculations.dart`), persisted the active workout after every change with safe restore of corrupt data, and wired validation into `logSet`. Added screen wake lock during workouts. 27 new unit tests (calculations, persistence, state machine). Verified resume-after-kill and wake lock on the emulators. Also corrected an earlier overclaim: `flutter test` uninstalls the app, so the media-cache refresh was only unit-tested; verified it properly with a pre-seeded stale cache on both platforms | See commit history |
| 2026-10-16 | Closed Phase 2: ran the full seed (20 drill docs plus media in production) and verified the exit criterion on the Android emulator with the network off (library lists all 20 drills; a previously viewed demo plays). Placeholder-video replacement stays open as a launch blocker | See commit history |
| 2026-10-16 | Per the user, filled every missing video with a shared Skills Vault clip: all 20 drills plus a shared lesson/trailer/welcome clip now carry a burned-in "PLACEHOLDER VIDEO · REPLACE BEFORE LAUNCH" banner; uploaded all 21 to Storage. Program trailer, lesson, and welcome screens now play the placeholder through the same media card. Added cache version checks so a replaced upload refreshes devices (offline keeps the cached copy). Verified on both emulators (cache refreshed to the new file); analysis clean, 77 host tests pass | See commit history |
| 2026-10-16 | Added `video_player` drill demos hosted in Firebase Storage: deployed Storage rules (signed-in `get` on `drills/*` only) with rules tests, added a `--media-only` seed mode and uploaded the 10 placeholder clips/posters to `how-to-hockey`, a disk-cached media source with next-drill prefetch, and a looping muted DrillMediaCard with reduced-motion and placeholder fallbacks. Fixed a self-waiting future in the download dedupe (caught by tests) and made startup replace a dead anonymous session (iOS simulator had a stale user whose token could not refresh, so Storage returned unauthenticated). Verified playback and caching on both emulators; analysis clean, 75 host tests and 19 rules tests pass | See commit history |
| 2026-10-16 | Visual QA on both emulators after the copy rewrite (clean; one memory-pressure ANR did not reproduce). Wired the Drill Library to the bundled 20-drill catalog: loading/error states, skill tabs, Pro-gated setup filters, catalog-backed drill detail and routine builder; aligned the sample workout ids with the catalog and made the primary skill the highest-weighted one. Added catalog/filter tests and a shared test catalog override. Analysis clean, 63 host tests pass; verified on both emulators | See commit history |
| 2026-10-16 | Transcoded 10 Skills Vault clips to spec (4 s, 720p, muted, <1 MB, plus posters) as local gitignored placeholder media for 10 hands/shooting drills; rewrote all app copy in the Coach Jeremy / The Pond voice with honest "isn't live yet" messaging and updated tests; added the voice guide to the Copilot reference. Analysis clean, 56 host tests pass | See commit history |
| 2026-10-16 | User approved the UX-first screens; resumed Phase 2. Moved the seed validator/schema to the six skills (legacy names rejected), enforced the media spec (≤1.5 MB, same-name poster JPG) with a metadata-only `--skip-media-check` mode, authored the 20 free starter drills (all six skills and tracking types), added Node and Flutter catalog tests, and documented the media spec and seed commands | See commit history |
| 2026-10-16 | Emulator/simulator QA (iPhone 16 Plus, Android API 36; light and dark). Fixed arena panels showing dark-on-dark text in the light theme and the collapsed weekly training chart. Updated the stale live integration test (six skills, new workout-panel actions) and made it restore the test error handler so failures are visible. Both platforms pass | See commit history |
| 2026-10-16 | Cross-screen review: added a sweep test rendering every static route in light/dark at 320×568, 200% text, and Reduce Motion with no overflow/exceptions; fixed the workout sheet's settle animation ignoring Reduce Motion. Fixed the VS Code Gradle import error (JAVA_HOME was JDK 27-ea, unsupported by Gradle 9.3.1) by pinning `java.import.gradle.java.home` to Temurin 17 in `.vscode/settings.json`. Analysis clean and all 55 host-only tests pass; no simulator walkthrough done | See commit history |
| 2026-10-16 | Built welcome, birth-year age gate (under-13 directed to a parent-created child profile; no free-text inputs), provider sign-up placeholders, multi-role onboarding into each shell, Player/Coach Pro paywall with plan/billing toggles, restore/manage entries, and program storefront/detail/day/lesson with owned vs locked states. Reachable from Me, Parent Account, Coach Team. All unconnected actions disclose status. Analysis clean and all 53 host-only tests pass | See commit history |
| 2026-10-08 | Built the Coach shell slice: separate Roster · Homework · Compliance · Team navigation; roster with join requests, assign-homework flow (routine, due date, players), compliance dashboard with date-range chips and per-player progress, team join code/visibility/verification entry, and Switch to Player. No player search or free-text input. Role switcher on Me opens Coach. All unconnected actions disclose status. Analysis clean and all 51 host-only tests pass | See commit history |
| 2026-10-08 | Built the Parent shell slice: separate Kids · Verify · Account navigation, child detail with local leaderboard-hiding toggle, remove-from-team confirmation, kid-device pairing (sample code), join approvals, Train Together, and Train-as-child shortcut. Player Me role switcher now opens Parent; Account switches back to Player. Every unconnected action discloses its status. Analysis clean and all 50 host-only tests pass | — |
| 2026-10-08 | Replaced the session header's "ACTIVE · EST." with a subtler **TRAINING** label that marks the time counting toward overall training; a `~` prefix flags partly estimated values, with a screen-reader explanation and updated overview note. Analysis clean and all 48 host-only tests pass | See commit history |
| 2026-10-08 | Moved the workout panel into the shared Player shell so its collapsed header survives Train/Progress/Team/Me navigation, with screen clearance and retained logs/drafts. Detail routes and root-level modal sheets cover the panel. Replaced stacked previews with a single horizontal row of exact 9:16 cards that follows drill selection; kept Log/Finish at the end of the vertical scroll and dismissed completed panels without losing summary data. Analysis clean and all 48 host-only tests pass; refreshed only the identified iPhone simulator. Parent remains the next UX slice | — |
| 2026-10-08 | Assessed the pending Player Team/Me and workout-sheet changes against the roadmap: 7 of 12 UX-first checklist items complete, Parent shell next, production backend/content criteria unchanged. Updated status and the development reference, including explicit emulator-only device targeting. Flutter analysis clean and all 43 host-only unit/widget tests pass. An unintended physical-device integration run failed and is excluded from acceptance evidence. Committed the six-file Player UX and documentation change set | See commit history |
| 2026-10-05 | Reworked the active workout sheet to the user's spec: Log/Finish action moved to the end of the shared vertical scroll, drill previews converted to a portrait three-per-row grid in that same scroll (six drills on one screen), tapping a preview now switches drills, and drill instructions moved behind a new **Drill details** action. Derived sheet extents from a `LayoutBuilder` inside the shell body so the collapsed red header parks directly above the app navigation (matching TenThousandShotChallenge's SessionPanel/Navigation). Fixed the collapsed-sheet RenderFlex overflow. Updated regression coverage for the new scroll/tap behavior; Flutter analysis clean and all 43 tests pass; verified expanded and collapsed states on the iPhone 16 Plus simulator with no runtime errors | — |
| 2026-10-05 | Completed the Player Team slice (member/no-team/locked preview states, locker-room posts with stick taps, weekly leaderboard, homework hero, team discovery and join-with-code sheets) and the Player Me slice (profile switching, role switcher, account and subscription entry points, retained appearance controls), with every unconnected action disclosing its status. Added Team and Me regression tests; Flutter analysis clean and all 43 tests pass | — |
| 2026-10-05 | Committed the pending workout navigation, synchronized sheet collapse, separate drill details, and regression coverage at the user's request; retained the verified 41-test and clean-analysis baseline and checked whitespace before committing | — |
| 2026-10-05 | Moved session drill media/instructions to a separate thumbnail-opened details screen using actual session drills; viewing details leaves active selection and logs intact and pauses timed inputs. Swipes highlight the active preview and keep it visible. Removed synthesized drag events from the header, fixing diagonal collapse assertions and settling canceled drags safely. Added custom-drill/draft, timer-pause, highlighted-preview, and diagonal/cancel regressions; Flutter analysis and all 41 unit/widget tests pass. No running app is connected for live simulator validation | — |
| 2026-10-05 | Reproduced the duplicate Navigator page-key assertion through the actual Train → View workout → Start workout buttons; nesting alone did not fix pushing a second shell above the existing shell. Changed all five session-start actions to `go`, replacing preview/setup history with Train/session, and restored the Train background beneath the opaque session page. Added actual-button regression coverage for workout preview, saved routines, drill detail, Shot logger, Timer, setup/focus, and Back to Train; Flutter analysis and all 39 unit/widget tests pass. Hot-restarted the connected iPhone simulator; automated live taps are unavailable because the driver extension is disabled | — |
| 2026-10-05 | Nested the session route beneath Train (retaining a `/session` redirect alias) and removed the duplicated Train page from the session overlay to prevent duplicate GoRouter page keys when opening a workout from a pushed route; added a push-flow regression test | — |
| 2026-10-05 | Fixed workout-sheet collapse by giving the red status header a dedicated drag surface and lowering its minimum extent; the app navigation now slides down/up in sync with sheet expansion/collapse while staying reachable when minimized | — |
| 2026-10-05 | Reworked the active workout sheet with one shared vertical scroll body for title, drill previews, rest controls, and drill pages; pinned the red status header and Log/Finish action, floated the sheet above the app navigation, and kept shell navigation usable while collapsed. Updated regression coverage for scrolling, logging, minimized navigation, and timed drills; Flutter analysis and all 34 unit/widget tests pass | — |
| 2026-10-05 | Simplified active workout interaction by removing the competing manual drag recognizer and making the sheet’s shared scroll controller drive native resize/scroll behavior; retained only a pinned status header while title, overview, previews, and drills scroll together. Replaced the Train app-bar action logo with a centered wordmark. Added regression checks and passed Flutter analysis plus all 34 tests | — |
| 2026-10-05 | Refined the workout sheet so its minimized state keeps only the drag handle and training status while the title/actions, drill previews, rest controls, and drill pages scroll in the sheet; fixed narrow/high-text-scale layout and verified logging, overview, timer, and rest flows. Added local routine library/build/edit flows with sample and skill-template drills, documented the future RevenueCat cap/entitlement hook, aligned the rink’s red center line with its center faceoff circle, and passed Flutter analysis plus all 34 tests | — |
| 2026-10-05 | Replaced active session's full-screen layout with a draggable workout sheet over Train, added selectable swipeable drill previews, and motion-forward accessible bottom navigation; replaced the five legacy categories with Accuracy, Hands, Power, Passing, Speed/Strength, and Endurance, including legacy catalog-key migration and six-skill sample coverage; Flutter analysis and all 33 unit/widget tests pass, including light/dark and 200% text-scale coverage | — |
| 2026-10-05 | Reworked the visual treatment after user feedback that the first pass was too subtle: ice-tinted light canvas, dark navigation rail and arena panels, illustrated rink hero cards, colorful drill tiles, and weekly training bars. Kept the established brand red/cream, Inter, and functional behavior; verified Train and Progress on-device plus focused, high-text-scale, and Player-flow tests | — |
| 2026-10-05 | Refreshed the Player screens with a MacroFactor-inspired high-contrast, data-forward treatment translated to locked How To Hockey tokens; added sample skill radar, PR Vault, lifetime totals, session detail, and share-card preview. Added responsive layout and preview widget coverage; analyze and focused tests pass | — |
| 2026-10-05 | Rechecked the remaining VS Code Problems: all reported imports and cascaded errors are from three deleted preview files; no Dart sources retain preview references and `flutter analyze` passes. No source changes needed; refresh the stale editor tabs/analysis server | — |
| 2026-10-05 | Simplified the public README to the app purpose, development status, high-level setup, and checks; preserved detailed development/release notes in .github/COPILOT_REFERENCE.md and linked them from agent instructions | — |
| 2026-10-05 | Revised compound startup to prepare both virtual devices sequentially before starting either debugger, rather than relying only on each debug profile's boot task; individual profile boot checks remain available. CLI launch success does not verify the VS Code compound launch itself | — |
| 2026-10-05 | Restarted VS Code Dart analysis after user enabled macOS automation permission; full Problems panel now reports no errors, Flutter analysis passes, and committed compound preparation plus troubleshooting documentation | — |
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
| 2026-10-05 | Initially implemented the UX-first request as a separate preview (later corrected below); added Player navigation, Train/setup/focus/routine/library/detail, six logging styles, rest and summary; analysis, 20 unit/widget tests, and offline iOS integration test passed | `bf65929` |
| 2026-10-05 | Corrected UX-first scope to actual app screens: normal Firebase-backed launches now open the Player shell, moved UI/state into the app layer, removed separate preview flag/profiles/banners and timer fast-forward control; hot-restarted the connected iPhone Live app and confirmed Train renders with no runtime errors; analysis and all 20 unit/widget tests pass | — |
| 2026-10-05 | Reworked actual training UX into swipeable drills and workout overview with independent set progress, retained inputs, elapsed/estimated active training time, explicit Finish workout, and optional inline rest off by default; per-drill rest preferences persist on-device and are editable from session/detail; analysis, 29 unit/widget tests, and normal Firebase-backed iOS Simulator integration test pass | — |
| 2026-10-05 | Added Android + iOS Emulators (Live) compound debug launch, individual virtual-device profiles, boot/readiness tasks, and usage documentation; user selected live Firebase; committed the launch setup together with all pending training UX changes | — |
| 2026-10-05 | Investigated reported launch/editor errors: current source and launch/tasks have no diagnostics, CLI analysis passes, editor problems reference deleted preview files, and pasted syntax errors predate successful hot reloads. Ran both boot tasks and simultaneous live-Firebase Flutter launches, confirmed Train in both widget trees and no runtime errors; documented stale-editor recovery without masking diagnostics | — |

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
Modern, athletic, and data-forward, in the style of **MacroFactor Workouts** but with How To Hockey branding:
- **Expressive arena surfaces:** ice-tinted light canvas, charcoal feature panels with subtle rink-line artwork, and dark navigation that anchors both themes. Use restrained gradients only to give the feature panels depth; avoid ornamental clutter.
- **Brand and skill color:** How To Hockey red remains the primary action/accent; use the existing pillar colors to distinguish hockey skills in charts, drill tiles, and progress views.
- **Big, confident numbers:** stats, timers, and set inputs are the hero of each screen (large tabular numerals, small uppercase labels).
- **Card-based layouts** with generous spacing; use dark data panels, illustrated workout heroes, and colored skill indicators to make the training surfaces feel unmistakably sporty.
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
| `bg` | `#F1F4F8` | `#0E0E10` | Ice-tinted light canvas; not pure black in dark mode |
| `surface` | `#E6EBF1` | `#1A1A1D` | Soft contrast surfaces |
| `surfaceElevated` | `#FFFFFF` + hairline border | `#232327` | Sheets/dialogs; dark mode uses lighter surfaces instead of shadows |
| `textPrimary` / `textSecondary` | `#111114` / `#626D7B` | `#F5F5F7` / `#9A9AA3` | |
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
- **Navigation structure:** dark bottom navigation rail per role shell with a brand-red active indicator and preserved tab state (`StatefulShellRoute`), large collapsing titles (`SliverAppBar.large`), modal bottom sheets for quick inputs/filters, full-screen immersive mode for active sessions.
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
- **Train home:** illustrated dark rink hero for today's suggestion, quick-start setup chips (location/pucks), saved routines carousel, streak + weekly time ring.
- **Active session:** dark-leaning immersive layout in both themes, swipeable drill pages, media card top, huge input/timer center, sticky action bar bottom; workout overview with completion status, drill jumping, elapsed and training time.
- **Rest timer:** optional inline countdown, off by default and configured per drill; `−15s` / `+15s` / `Skip` controls do not block drill navigation or logging. *(User-approved workflow revision, 2026-10-05)*
- **Progress:** dark weekly-load chart, skill radar on an arena panel, colorful PR tiles, lifetime totals as big-number tiles.
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
- [ ] Optional Figma companion: the actual Flutter screens are the design-review source of truth during UX-first work; a Figma file is no longer a prerequisite for UI work
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
- [x] Media spec: 3–5s MP4, 720p, muted, ≤1.5 MB, plus poster JPG *(documented in the Copilot reference; the seed validator enforces size, existence, and a same-name poster JPG)*
- [ ] **REPLACE ALL PLACEHOLDER VIDEO before launch:** every drill demo and the shared lesson/trailer/welcome clip (`drills/placeholder-lesson.mp4`) is a Skills Vault stand-in with "PLACEHOLDER VIDEO · REPLACE BEFORE LAUNCH" burned in. Produce final Coach Jeremy demos for all 20 drills plus real lesson/trailer/welcome video, re-run `seed:drills -- --live`, and confirm no banner remains (devices refresh cached clips automatically when the upload changes)
- [x] Seed the **20 free starter drills** covering all 5 pillars and all 6 tracking types *(20 free drills across all six skills and tracking types uploaded to Firestore `drills/` and Storage on 2026-10-16; their videos are placeholders, tracked by the REPLACE ALL PLACEHOLDER VIDEO item)*
- [x] Drill Library screen: list, detail, looping media card, form cues *(demos play muted and looping from Firebase Storage via `video_player`; reduced-motion players get a still poster; drills without a clip show the illustrated placeholder)*
- [x] Filters: location, puck inventory, ball type, passer, pillar, tracking type (filters are Pro-only per tier matrix; free sees the starter 20) *(setup filters sit behind Player Pro via a local stand-in flag until RevenueCat in Phase 8; the skill tabs stay free)*
- [x] Media caching and preloading of the next drill's video *(demos are downloaded once to app storage and replay offline; the workout panel warms the current and next drill)*

**Exit Criteria:** All seed drills browsable offline after first load.

---

## UX-first — Actual App Screens (Current Priority)
Clarified by the user 2026-10-05: pause scheduled backend/content work and build the complete intended UX as the actual app screens, with local placeholder data and media until functionality is implemented. Do not create a separate prototype, preview app, or opt-in screen flag. Existing architecture, design tokens, tier rules, separate role shells, and no-UGC constraints stay locked.

The normal Live and Emulators launches show these screens with the existing Firebase initialization and anonymous sign-in intact. Local Riverpod data/state providers are temporary sources for the real UI, to be replaced or extended as production functionality is implemented. They do not pretend to persist history, update stats/feed, or perform purchases. Use bundled/illustrated media placeholders, not remote image services. Backend acceptance criteria remain independent of UI completeness.

Work these slices in order, reviewing the visual direction between slices:
- [x] Normal app launch opens real Player routes, local fixtures, shared branded components, and preserved Player tab navigation
- [x] Player training: Train home → setup/focus → routine detail → all six set-input types → optional inline rest → summary; drill library/detail and manual logger entry points
- [x] Training workflow refinement: swipe between drills, workout overview/jump/status, retained draft inputs, independent set completion, elapsed/estimated active time, and device-persisted per-drill rest settings (off by default)
- [x] Routine management UX: routine library and builder/edit flows combine sample-library drills with preset skill-template drills and save locally; RevenueCat limits/entitlements and cloud sync remain future integrations
- [x] Player progress: radar, PR Vault, lifetime totals, session history/detail, share-card preview (representative sample data; history and sharing remain unconnected)
- [x] Player team: locker room, stick taps, leaderboards, homework, invite/join/discovery, member-only/empty/locked states
- [x] Player Me: appearance, profile switching, role switcher, account/subscription entry points
- [x] Parent shell: Kids, child detail/controls, Verify, Account, kid-device pairing, join approvals, Train Together
- [x] Coach shell: Roster, Homework/builder/assignment, Compliance, Team settings/invites/verification
- [x] Welcome/signup/age gate, role onboarding, paywalls/restore/manage, program storefront/detail/day/lesson
- [x] Review every screen in light/dark, 200% text scale, small phone sizes, and Reduce Motion; include loading/empty/error/locked states where applicable
- [x] User approval of screen inventory, navigation, visual design, and core flows before resuming backend/content milestones

**Exit Criteria:** All planned screens are navigable in the normal app using representative placeholder data/media; user approves the UX direction. Unimplemented operations disclose their status instead of reporting success. Production roadmap checkboxes stay unchecked unless their original functional criteria are independently met.

---

## Phase 3 — Active Training Engine (Core Loop Step 2)
Build as a pure-Dart `SessionController` (Riverpod Notifier) with a thin UI on top so it is unit-testable.

- [x] Production session controller: independent per-drill progress, swipe/overview selection, optional concurrent rest, explicit completion → summary *(validated set entries, persisted after every change, and unit-tested; rest-end notification is a separate item)*
- [x] Top bar: "Drill X of N" + overall timer (wall-clock based); overview with per-drill status and production active-time accounting *(wall-clock elapsed time, active time from measured sets with estimates marked, and per-drill status in the overview)*
- [x] Media card with looping demo + 3 form cues *(kept compact by design: the demo and cues open from the play-icon Drill details button on the workout card, using the same looping, cached video card as the library)*
- [x] Dynamic Input Module, one widget per `TrackingType`:
  - [x] **Volume:** stepper + direct numeric entry per set
  - [x] **Duration:** countdown with start/stop chimes, 3-2-1 lead-in *(wall-clock `SetCountdown` with a 3-2-1 lead-in, start and stop cues, pause/resume and cancel, all unit-tested)*
  - [x] **Density:** timer → numeric pad → computes SPM = `reps / seconds * 60` *(SPM computed by the shared, unit-tested calculation)*
  - [x] **Accuracy:** hits / total → accuracy %; validate `hits ≤ total` *(enforced in the controller and the input)*
  - [x] **Streak:** single numeric entry for max consecutive
  - [x] **Binary:** large toggle per set
- [x] Action bar: `Log Set`, `Swap Drill` (same `swapGroup`, still matching setup), `Rest Timer` *(Swap Drill offers same-group drills that fit today's setup (only before a drill has logged sets); Start rest begins a manual rest for any drill)*
- [x] Production rest mechanics: off by default, configurable enable/duration per drill; when enabled auto-start inline after Log Set except the final workout set; `+15s`, `-15s`, `Skip Rest`; chime + haptic on end *(rest-end chime and haptics added; skipping a rest stays silent)*
- [x] Local notification when rest ends while app is backgrounded *(scheduled only when the app goes to the background and cancelled on return, so it never doubles with the in-app chime; permission is asked once, at the first rest; Me → Workout has a Rest reminders switch. Verified end to end on the Android emulator: scheduled, fired on time, correct text and icon. Not verified on iOS: the simulator cannot grant notification permission from the command line, so check on an iPhone. Android uses inexact alarms, so a locked phone in Doze may deliver it a little late)*
- [x] Wakelock on during session; audio session mixes with user's music *(wake lock verified on both emulators; cues use an iOS `ambient` / Android no-focus audio session so music keeps playing and the silent switch is respected; the audio session is configured on both platforms without errors, but audible output could not be judged on emulators)*
- [x] Persist session progress after every set (resume after app kill) *(verified on the Android emulator by force-stopping the app and relaunching: workout, sets and elapsed time were restored)*
- [x] Session summary screen with totals per drill *(per-set results with derived shots-per-minute and accuracy, plus a headline total per drill)*
- [x] **Manual loggers (free tier):** standalone Shot Logger and Timer without a routine *(Shot Logger takes shots (optionally hits) in one tap-friendly screen and Timer takes any length from 30 s to 20 min with the usual 3-2-1 and cues; both run through the saved, summarised session and ask before replacing a workout in progress)*
- [x] Unit tests for every tracking type's calculations and the state machine

**Exit Criteria:** A hard-coded routine can be run end to end, killed mid-session, resumed, and saved. *(Status 2026-10-16: run end to end, killed mid-session and resumed are done and verified on both emulators. "Saved" to the player's account is not: it needs player profiles (Phase 4) and the session write that Phase 6's `onSessionCompleted` listens for. Until then results persist on the device only.)*

---

## Phase 4 — Accounts & Profiles
- [ ] Firebase Auth: Sign in with Apple (required on iOS when offering third-party login), Google, email/password; `linkWithCredential` upgrades the Phase 1 anonymous user *(Email/password is built and verified end to end: a guest upgrades in place with `linkWithCredential`, keeping the same user ID; sign-in, sign-out, password reset, friendly errors. It is enabled in production. Sign in with Apple and Google are NOT done: they need setup in the Firebase console and Apple developer account first; see the Copilot reference.)*
- [x] Age gate at signup (birth year). Under-13 users cannot create an account; they must be created as a **child profile by a parent** (COPPA / GDPR-K) *(the sign-up flow collects the birth year first and only reaches the account form for 14+ years since birth year; the server refuses anything else)*
- [x] `users` / `profiles` split: one account can own multiple player profiles *(Firestore rules and `createOwnProfile`/`createChildProfile` Cloud Functions written and tested locally; not deployed yet)*
- [ ] **Any account tier (including Free)** can create and manage child player profiles (cap: 3, enforced in a callable Function) *(Server side done and tested: non-anonymous account, 3-child cap held under simultaneous requests, minors only. The Kids screen now lists and adds real child profiles with the cap message; Approvals and Verify show honest empty states until Phases 5-6.)*
- [x] Display name restricted to first name + last initial; server-side validation *(server-side validation in the Functions plus an identical client check, both driven by one shared set of test vectors)*
- [x] **Kid device sign-in:** parent generates a short-lived code → Function mints a custom token with a `profileId` claim → device is locked to Player mode for that child only (no parent, billing or account deletion). *(Built and verified against production: codes are 8 digits, hashed, single use, 10 minutes; kid-device tokens are refused by the profile and pairing Functions. Needs a QR option and App Check rate limiting before launch.)*
- [ ] **Shared device alternative:** on the parent's device, Player mode has a "Switch Player" picker for the parent's child profiles (optionally PIN-protected exit back to Parent/Coach mode)
- [x] Active profile is device-local state, so several devices on one account can run different profiles at the same time *(Saved on the device; a kid device is fixed to its one profile.)*
- [x] Account deletion flow in-app (required by both stores) → Function cascades data deletion *(Done and verified in production: deletes profiles with sessions, codes, kid-device sign-ins, then the sign-in; Phase 9+ must extend it to teams and feed data as they are built.)*
- [x] Firestore rules: a user can only read/write their own profiles' private data *(33 rules tests cover owner, stranger, signed-out, anonymous and a kid device locked to one profile; roles, entitlements, names, and totals are server-written only; not deployed yet)*

### 4B. Role-Based App Modes (Separate Shells)
An account can hold multiple roles (e.g., a coach who is also a parent). Each role gets its own navigation shell; a mode switcher in the account menu moves between them. Screens never mix concerns across roles.

| Mode | Bottom nav | Owns |
|---|---|---|
| **Player** | Train · Progress · Team · Me | Sessions, routines, radar/PRs, locker room, stick taps, homework. Bound to one active profile. |
| **Parent** | Kids · Verify · Account | Child profiles CRUD, each child's teams/invites/requests, workout verification, leaderboard visibility, subscription/billing |
| **Coach** | Roster · Homework · Compliance · Team | Team settings (visibility, join code), roster approvals, routine builder, assignments, compliance dashboard, verification |

- [x] `go_router` `StatefulShellRoute` per mode; redirect guards by role + active profile *(Guests can't open Parent or Coach; Coach/Parent role flags aren't required yet because a new parent has no role until their first child. Revisit with Phase 9.)*
- [x] Parent "Train as [Child]" shortcut jumps into Player mode for that child profile
- [x] Kid-device sessions only ever see Player mode
- [x] Widget tests asserting each shell exposes only its own routes *(Route-redirect unit tests plus a paired-device widget test.)*

**Exit Criteria:** Rules tests pass for owner/non-owner access; deletion removes all data.

---

## Phase 5 — Onboarding & Smart Coach Engine (Core Loop Step 1)
### 5A. Setup Parameters UI
- [x] Location picker (5 options)
- [x] Puck inventory (single select: Low/Medium/High)
- [x] Off-ice ball optional toggle (Golf Ball / Training Ball / Green Biscuit)
- [x] Passer optional toggle (Rebounder / Partner)
- [x] Remember last setup; allow saved presets ("Garage", "Rink Tuesday") *(Remembered on the device; up to 5 named setups.)*

### 5B. 100-Point Focus Scale
- [x] Five sliders and/or interactive radar *(Six sliders, one per skill; the radar view is part of Phase 6.)*
- [x] Zero-sum rebalance algorithm: when pillar *i* changes by Δ, distribute −Δ across the other pillars **proportionally to their current values**; if all others are 0, distribute evenly; clamp to [0,100]
- [x] Integer rounding via largest-remainder method so the total is always exactly 100
- [x] Unit tests: sum invariant, clamping, all-zero edge case

### 5C. Generation Algorithm (pure Dart, runs on-device)
1. **Hard filters:** `allowedLocations ∋ location`; `minPuckInventory ≤ inventory` (off-ice ball counts as satisfying inventory if drill supports it); `requiresPasser → passer present & type matches`; tier access.
2. **Score:** `score(d) = Σ focus[p] / 100 × d.skillWeights[p]` (+ small random jitter, − penalty if done in last N sessions).
3. **Allocate slots:** target session length (e.g., 20/30/45 min) → number of drills; allocate slots per pillar proportional to focus points (largest remainder).
4. **Select:** highest scoring per pillar slot, enforcing tracking-type variety and no duplicate `swapGroup`.
5. **Puck-inventory shaping:** Low → prefer single-puck / reset-and-retrieve and add retrieval time to estimates; High → allow density drills.
6. **Order:** warm-up (stickhandling/skating, low difficulty) → high-intensity shooting/density → finisher (streak/IQ).
7. **Prescribe:** use `defaultPrescription`, scaled by difficulty and recent performance.
- [x] Deterministic seed option for tests
- [x] Golden tests for known setups → expected routine
- [x] Free tier can generate custom routines (from the 20 starter drills) but may keep **max 3 saved routines** per profile; Player Pro = unlimited saves + full 100+ drill pool *(Generation and the 3-routine cap work on the device; Pro unlock is a stand-in until Phase 8.)*
- [ ] Enforce the saved-routine cap server-side: `createSavedRoutine` callable Function checks entitlement + count (rules can't count docs); client shows "replace a saved routine" prompt when at cap
- [ ] Downgrade handling: if Pro lapses with >3 saved, keep all readable but block new saves until ≤3

**Exit Criteria:** User picks setup + focus → receives a valid routine → runs it in the Phase 3 engine.

---

## Phase 6 — Analytics & Progression (Core Loop Step 3)
- [x] Cloud Function `onSessionCompleted` (Firestore trigger): *(Deployed to production in northamerica-northeast2, next to the database.)*
  - [x] Validate set logs (sane ranges; reject impossible values, e.g., >5 shots/sec)
  - [x] Compute **active training seconds** (the shared unit for radar and leaderboards):
    - duration/density sets → timed seconds actually run
    - volume/accuracy/streak/binary sets → drill's `estimatedSecondsPerSet`
    - rest time excluded; per-session and per-day caps (Remote Config, e.g., 4h/day) to block idle-timer gaming
  - [x] Update `stats/lifetime` (shots, activeSeconds, routines, `pillarSeconds[p] += setSeconds × skillWeights[p]`)
  - [x] Evaluate PRs per metric key (e.g., `accuracy_10shot_pct`, `density_30s_shots`, `streak_juggle`)
  - [x] Compute daily streak
- [x] **Skill Radar** (decision: absolute levels on training time): *(On-device. Overlay is the focus plan, tap a skill for level, hours and top drills.)*
  - Each pillar has Levels 1–10 from cumulative `pillarSeconds`; thresholds grow geometrically (e.g., L1 = 1h, ×1.65 per level → L10 ≈ 90h), tunable in Remote Config *(done: `progress_level_one_seconds`, `progress_level_growth`)*
  - Vertex = `level + progressToNext` so it visibly grows every session and never shrinks
  - Time (not reps) is used because reps are not comparable across tracking types (a juggle streak ≠ a slap shot ≠ a footwork set)
  - Faint overlay polygon shows the player's current 100-point focus allocation (plan vs. actual work)
  - Tap a vertex → level, hours, top drills for that pillar
- [x] **PR Vault:** categorized by metric type, with date and link to session *(On-device, by kind with date; opens the workout while it is still in history.)*
- [x] **Lifetime Totals:** shots, hours, routines completed *(Shots, hours, workouts, streaks.)*
- [x] Session history list + per-drill breakdown charts (Pro) *(History list shows the latest 60 workouts on this device; the breakdown draws from them and sits behind the Player Pro stand-in until Phase 8.)*
- [x] Gate: free sees lifetime totals; Radar, PR Vault, breakdowns are Player Pro *(Stand-in flag until Phase 8 purchases.)*

**Exit Criteria:** Completing a session updates totals, radar, and PRs within seconds.

---

## Phase 7 — Native Share Cards
- [x] Branded card widget (session stats, streak, PR badges) rendered offscreen at 1080×1920 and 1080×1080 *(Story and Square; stats, streak and personal-best badges.)*
- [x] `RepaintBoundary.toImage` → PNG → `share_plus` share sheet
- [x] No upload to servers; nothing stored remotely *(Cards are made on the phone and the temporary file is deleted after sharing.)*

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
- **Persistent session panel and preview carousel (supersedes the grid contract):** The active panel is shared across all main Player tabs; collapsing or leaving the opening route does not dismiss the workout. Pushed sub-screens and root-level detail/settings sheets cover the panel. Previews must be exact 9:16 cards in one horizontal row, not a grid, and the carousel scrolls to highlight the drill selected by swiping or tapping. The preview row and final Log/Finish action remain in the vertical session scroll. *(User clarification, UX-first, 2026-10-08)*
- **Active workout sheet layout (supersedes earlier sheet contract):** Only the red status header stays pinned; the Log/Finish action is the last item in the sheet's single vertical scroll. Drill previews are a portrait three-per-row grid inside that same scroll so a six-drill workout fits on one screen. Tapping a preview card now **switches** to that drill (previously it opened the details screen); drill instructions/media stay at `/session-drills/:id` reached from a **Drill details** action inside the active drill. The sheet is sized from a `LayoutBuilder` within the shell body, so the collapsed minimum equals the status header height and the red header parks directly above the app navigation — matching the reference `SessionPanel`/`Navigation.dart` behavior. *(UX-first, 2026-10-05)*
- **Bolder visual direction:** After the initial visual refresh did not meet the user's request, the user reiterated that the app should feel more visibly inspired by MacroFactor Workouts. This approves a more expressive sports-dashboard treatment: ice-tinted light backgrounds, charcoal arena panels, rink-line illustration, and coordinated skill-color accents. Preserve the How To Hockey logo, brand red/cream, Inter typeface, accessible contrast, and both light/dark appearance modes. *(UX-first, 2026-10-05)*
- **Training workflow:** User requested a Macrofactor-style workout flow: swipe between drills or open an overview with workout status/info/time, rather than forced sequential rest screens. Rest is optional, off by default (user-confirmed), with per-drill enable/duration settings saved on this device for now. Timed drill inputs pause when leaving their page; rest does not block swiping/logging. Local active-time estimates are disclosed and are not production leaderboard accounting. Backend resume/history/audio/background notification requirements remain outstanding. *(UX-first, 2026-10-05)*
- **Player skills and active workout presentation:** Use Accuracy, Hands, Power, Passing, Speed/Strength, and Endurance as the six training skills. Accuracy and Power are shot-focused categories. Keep the active workout in a draggable bottom sheet over Train, with selectable horizontal drill previews linked to the existing swipeable drill pages. Preserve older catalog skill keys by migrating them at decode. *(UX-first, 2026-10-05)*
- **UX-first actual screens:** Pause Phases 2–14 backend/content work to build all planned screens in the normal Flutter app with placeholder data/media, then connect functionality to those same screens. The earlier separate opt-in preview was a misunderstanding and is superseded by the user's clarification. Flutter replaces the Figma-before-UI prerequisite. Work Player training first, then remaining Player, Parent/Coach, and account/commerce/program flows. *(UX-first, 2026-10-05)*
- **Local testing priority:** Use the Samsung S24 debug launch against live Firebase with its registered App Check debug token; defer remaining production signing, Play Console, DeviceCheck, and enforcement work until release preparation. This deferred Phase 1 item does not block local development or the remaining foundation work. *(Phase 1)*
- **iOS SwiftPM Git policy:** Use an approved process-scoped `safe.bareRepository=all` exception for trusted iOS dependency builds when the machine requires explicit bare repositories; do not weaken the global Git policy or replace SwiftPM. See the build command in [.github/COPILOT_REFERENCE.md](.github/COPILOT_REFERENCE.md#ios-builds-with-restricted-bare-git-repositories). *(Phase 1)*
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
- **Voice and tone:** App copy follows the Coach Jeremy / The Pond voice (plain, warm, second-person, short sentences, light hockey flavor) and the TenThousandShots app's friendly empty states and prompts. Unimplemented actions must still say so plainly and never claim success ("isn't live yet. Nothing was changed."). Details in `.github/COPILOT_REFERENCE.md`. *(2026-10-16)*
- **Placeholder video:** Until final footage exists, every video slot uses a Skills Vault stand-in with "PLACEHOLDER VIDEO · REPLACE BEFORE LAUNCH" burned into the video and poster so it cannot ship unnoticed. Source clips stay in the gitignored `tool/seed/media/` (the repo is public) and are hosted in Firebase Storage under `drills/`. *(Phase 2, 2026-10-16)*
- **Drill catalog delivery:** The starter catalog (`tool/seed/drills.json`) is bundled as an app asset, so it is browsable offline and has one source of truth with the seed uploader; Firestore sync can layer on later. Skill tabs in the Drill Library are free; the location/puck/ball/passer/tracking filters are Player Pro. *(Phase 2, 2026-10-16)*
- **Drill media hosting:** Demos live in Firebase Storage under `drills/` (video plus same-name poster JPG). Storage rules allow a signed-in (including anonymous) player to `get` a known file only; listing and all writes are denied, uploads use the admin seed tool. Pro-only media will need entitlement-aware rules in Phase 8. *(Phase 2, 2026-10-16)*
- **Local workout history:** Until profiles and the cloud session write exist (Phases 4 and 6), finished workouts are saved to an on-device history (latest 60) when a workout is finished, and Progress shows real totals and recent training from it; the skill map, personal bests and weekly chart stay example data. *(Phase 3, 2026-10-16)*
- **Production backend (2026-10-19):** The `healthCheck`, `createOwnProfile` and `createChildProfile` callable Functions (2nd gen, us-central1, nodejs24) and the Firestore rules for users/profiles are deployed to `how-to-hockey`; an artifact cleanup policy deletes container images older than a day. Email/password sign-in is enabled.
- **Kid-device tokens (2026-10-19):** `redeemPairingCode` mints a custom token, which needs `iam.serviceAccounts.signBlob`. In production the Functions run as the default compute service account (`591675097325-compute@developer.gserviceaccount.com`); grant it `roles/iam.serviceAccountTokenCreator` on itself: `gcloud iam service-accounts add-iam-policy-binding 591675097325-compute@developer.gserviceaccount.com --member=serviceAccount:591675097325-compute@developer.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator --project how-to-hockey`. Pairing codes are 8 digits, hashed at rest, single use, 10 minutes; rate limiting guesses (App Check) is a Phase 14 item.
