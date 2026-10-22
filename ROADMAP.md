# How To Hockey — Build Roadmap (Flutter + Firebase, iOS & Android)

This roadmap turns the product spec into ordered, checkable milestones. Each phase ends in a shippable or testable state. Work top to bottom; do not start a phase until the previous phase's **Exit Criteria** are met. The UX-first app-screen milestone below temporarily takes priority over Phases 2–14.

## 📍 Current Status
> Update this block at the end of every work session.

- **Current phase:** Core-functionality QoS pass completed, including the user-approved Phase 9 membership/invite slice ahead of the remaining Phase 8 work. Phase 7 is complete; Phase 9 feed, standings and homework are not complete.
- **Next task:** Start **R1** (landing walkthrough + outcome-first Train) and **R2** (Simple guided session + Standard toggle + parent confirmation) per the scheduled track — all R0 questions are answered — with **R4 Programs** pulled forward and Phase 8 purchase verification on a parallel track. Also pending: close the remaining core QoS verification gap: cold-start invite handoff on both platforms, then distribute updated mobile builds. The user redirected this session to a Hevy UX assessment; recommendations are recorded in the reference, not approved implementation scope. Resume Phase 8 in order: RevenueCat Google service-account validation, sandbox purchase/restore/expiry on both platforms, Coach Pro gating, saved-routine cap, Signature Programs and the team grant. Child profile edit/delete and remaining team activity are unfinished follow-on slices; Apple/Google sign-in still needs console setup.
- **Validation:** On 2026-10-20: clean `flutter analyze`; 350 host Flutter tests, 60 Functions unit tests plus 9 catalog checks, 54 Firestore-emulator backend tests and 43 rules tests pass. iPhone 16 Plus and Android API 36 native E2E pass against local Auth/Functions/Firestore, including real OS invite-URL handoff, guest upgrade, login, children, profile switching, joining, parent approval, assistant coach invites, removal and deletion. True cold-start handoff remains unverified: the new Android harness hit emulator storage limits, and the iOS harness terminated/opened the app but timed out discovering its VM service; neither is a confirmed app-routing failure. The cold-start test/runner remain work in progress. With user approval, the 8 team callables, 3 affected account/profile callables and Firestore rules were deployed; all report ACTIVE and unauthenticated `createTeam` returns HTTP 401. No production test accounts or teams were created.
- **Workout editing UX (2026-10-20, committed 4813b14):** Workout is now **scroll-first**: the default view is one list of drills, each a compact Hevy-style table (SET · PREVIOUS · inputs · ✓) logged in place; the old one-drill carousel/timer is the optional *Focus view* (toggle remembered on the device, or via a drill's menu). Secondary actions (details, rest timer, move/replace/remove, end early) sit behind each drill's ⋯ menu. Also: shared drill picker, reusable *My drills*, routine reorder/set-count/duplicate, per-player *Last time* (PREVIOUS column and prefill), Repeat/Save-as-routine from history. 374 host tests pass; iPhone 16 Plus walkthrough against local emulators inspected visually. Not verified: Android visual pass (emulator storage), routine *last performed*, drag-to-reorder, routine folders, historical result editing, cloud history recovery.
- **Product direction (2026-10-21):** The user restated the app's fundamentals (training sessions as the core, "get a better ___", a kid-proof video-led session, the Coach → Parent → Player growth loop, and pain-point Programs as the paid value). See **Product Direction & Redesign Requirements** below the Session Log; the fit assessment there is the next piece of work and nothing has been redesigned yet.
- **Blockers:** Apple/Google sign-in console setup and the outstanding Phase 8 purchase verification/gates. Team feed, leaderboards, homework, child profile edit/delete, workout verification and sibling group workouts remain unfinished. Production App Check enforcement and release hardening remain deferred.
- **Last updated:** 2026-10-20

Detailed Copilot development notes live in [.github/COPILOT_REFERENCE.md](.github/COPILOT_REFERENCE.md); keep the public README focused on the app's purpose and high-level setup.

### Session Log
| Date | Summary | Commit |
|---|---|---|
| 2026-10-22 | **R3b done – parent corrections with audit (deployed).** Parent → child page → *Workouts*: counted workouts with **Fix time** (big ±1/5/10 buttons, 1–180 min, no keyboard) and **Remove**. New callable `correctSession` (parent of a child profile only) writes an audit record (`sessions/{id}/audits`: who, when, before/after; owner-readable, never client-writable), then re-works the child's totals, bests and PRs from their counted sessions (`rebuildStats`, last 500 sessions, honouring corrections/removals); the credit maths takes a `secondsOverride`. No automatic leaderboard exclusion (decision 3). Tests: 3 emulator + 1 rules + 3 host (398 host, 60 functions, 47 rules); emulator E2E (5 → 25 min changed the credited seconds, 1 audit) and iPhone simulator visual. Known limits: a rebuild racing a brand-new credit could drop that credit (fixed by the next correction/credit order; acceptable pre-launch); parent-created workouts for kids are still via *Train as* + device routines until R3c | This commit |
| 2026-10-21 | **Deployed R2c** (Firestore rules + `onSessionCompleted` as a write trigger) to the live project. **R3a done – coach's one free team routine:** server callables `setTeamRoutine` / `clearTeamRoutine` (coach-only, name 2–40 chars, 1–10 library drills, 1–10 sets; replacing or clearing archives the old one to `teams/{id}/routineArchive`); coach Team page → *Share a routine* (from saved routines using library drills only) / *Replace* / *Stop sharing*; players, parents and kid devices on that team see **Coach's routine · Start** at the top of Train (the active player's membership decides; guests/other teams never see it). Tests: 2 emulator (functions 57), 3 host (395 total), emulator E2E + iPhone simulator visual. Both callables are deployed. Remaining R3: parent create/modify/time-correct sessions with audit (R3b), cloud per-profile routines + cap (R3c) | This commit |
| 2026-10-21 | **R2c done (multi-device confirmation).** A child's own device now uploads its finished workout as `pending` (rules: kid devices can only create `pending`; only the owning parent can flip it to `completed` with `confirmedAt` or delete it). `onSessionCompleted` is now a write trigger that credits only `completed` sessions, so confirming counts it once; pending drafts credit nothing. Kid sees *Waiting for a grown-up*; the parent sees a *Waiting for you* queue on Train → *Check the workout* → Confirm & save / Discard. Offline drafts reuse the sync ledger (`pending` flag). 6 rules tests, 1 function test, 6 host tests, emulator E2E (pending uncounted → confirm → counted; discard never counted), simulator-verified. **Not deployed yet** (rules + `onSessionCompleted` need `firebase deploy`); push notification for the parent is deferred (needs FCM/APNs setup) — the in-app queue is the notice for now | This commit |
| 2026-10-21 | **R2b done (single device).** A parent-managed child's finished workout no longer saves itself: the Simple view's final action becomes *Hand to a grown-up* → review screen (all drills/sets, **Confirm & save**, *Fix a result* → editable list). Until confirmed the workout is pending: Train shows a *Waiting for a grown-up* card first, and nothing is counted or synced. Own-account players (incl. teens) save as before. 3 new host tests (389 total), simulator-verified on iPhone 16 Plus. Multi-device (pending draft upload, parent review queue + push, server credit on confirm) is R2c | This commit |
| 2026-10-21 | **R2a done.** Active workout defaults to the Simple view: video hero, one drill at a time, big count/timer buttons, pinned 64 dp Done/Next drill/Finish action, per-drill progress strip, secondary actions in a More menu. Standard list view is a persisted toggle. Host tests and analyze pass; simulator-verified on iPhone 16 Plus (fixed an invisible progress-strip track); R2b (parent confirmation) is next | This commit |
| 2026-10-21 | **R1 started.** Train now asks "What do you want to get better at?" with six outcome buttons (harder shot, better accuracy, quicker hands, faster & more explosive, sharper passing, more stamina) that point today's workout at a skill; one **Start workout** (or **Resume workout** when one is under way — it no longer silently replaces it); setup, skill mix and routines move into a "Customize" section. New first-launch **welcome walkthrough** (Player / Parent / Coach, honest *Soon* tags) replaces the single welcome screen and opens once on first launch. 386 host tests (12 new) and an iPhone 16 Plus fresh-install walkthrough inspected visually; Android not checked. Not committed | Uncommitted |
| 2026-10-21 | Closed the last R0 questions: routine-name free text exception confirmed; existing self-declared age gates (under-13, 19+ coach) kept. R1/R2 are ready to start. Documentation only | Uncommitted |
| 2026-10-21 | Recorded the follow-up answers: no age bands/voice-over; own-account teens untethered (confirmation only for parent-managed child profiles); unconfirmed sessions stay pending and kids see them; routine names from programs or free-text-with-cap by adults (explicit No-UGC exception). Flagged the conflict between "no age-based restrictions" and the existing under-13 birth-year gate and 19+ coach rule (kept pending the user's confirmation). Documentation only | Uncommitted |
| 2026-10-21 | Recorded the user's answers to the R0 decisions (Simple guided session default with Standard toggle; kids tap results and a parent confirms the whole session, single or multi-device; parents manage anything for their kids with audit; coach shares one free active team routine, 3-saved cap for all non-subscribers; "tailored" = skill-targeted content; Programs built now with placeholder media; first-run walkthrough previewing player/parent/coach). Added design consequences and open questions, resolved the tensions, scheduled the redesign track R1–R5 (Programs pulled forward). Documentation only | Uncommitted |
| 2026-10-21 | **R0 fit assessment** of the app against the product-direction requirements: screenshots of every guest-reachable screen on the iPhone 16 Plus plus code review of gated parent/coach screens, a screen scorecard, measured taps-to-start, findings per fundamental, a recommended order and eight open decisions. Headline: the session engine is solid but the surfaces are data-entry oriented (not kid-proof/video-led), Train is not outcome-first, Coach → Parent → Player membership exists but the work flowing through it (shared routines, assignments, parent-created workouts, audited time correction) does not, and Programs are example data buried under Me. Temporary audit harness removed. Documentation only | Uncommitted |
| 2026-10-21 | Recorded the user's product direction as requirements: five fundamentals (session-centred, "get a better ___" and fun, kid-proof video-led active session, Coach → Parent → Player loop, pain-point Programs as paid value), per-area requirement checklists, a Fit Assessment table of today's gaps, tensions with locked decisions (parent time correction vs server-authoritative writes, no-UGC, Coach Pro gating, Hevy-style list vs kid-guided flow, content readiness, phase order) and a draft redesign track R0–R5. Documentation only; no app changes, nothing approved yet | Uncommitted |
| 2026-10-20 | Workout editing UX pass from the Hevy assessment. Session notifier gained add/remove/move drills, add/remove-unlogged sets, end drill early, finish early, undo and correct a logged set (all persisted, none discarding logged results; saved workouts are read-only). New `workout_overview.dart` replaces the static overview; new `drill_picker.dart` is the single picker for routines, Add, Replace and Swap (Suggested, My drills, Recent, Library; search, skill filter, batch select). *My drills* persist structured template drills (reps, accuracy, duration, streak, completion; no free text). Routine builder uses the picker with set steppers, move up/down and duplicate; Summary from history can Repeat or Save as routine. Per-player *Last time* results use a new device-side workout-owner map, because sync entries are pruned once counted. Found and fixed while testing: the routine builder crashed for any routine not named from its fixed list (starter routine, copies); the picker header and routine drill rows overflowed at 320 px / 2x text; the overview header consumed the whole viewport at large text. 373 host tests (23 new); iPhone 16 Plus on-device walkthrough with screenshots inspected; Android visual pass blocked by emulator storage. Cold-start invite harness remains unverified (see reference) | 4813b14 |
| 2026-10-20 | Android native core-account/team E2E passed, including external invitation handoff. Cold-start harness remains unverified (Android installation storage; iOS VM discovery). User redirected to Hevy UX research: inspected signed-in routine library/editor, contextual exercise picker, custom exercise form/types, active logging, workout history/actions and calendar; discarded only the inspection-created workout draft without saving sets, exercises or routine edits. MacroFactor was excluded because sign-in was unavailable. Recorded prioritized hockey-specific UX proposals in the reference without changing locked decisions or app behavior | 4813b14 |
| 2026-10-20 | Committed the deployed core QoS slice and assessed follow-up priorities: close Android native and cold-start invite test gaps before distributing mobile builds; then resume Phase 8 purchase lifecycle verification and entitlement enforcement. Child profile edit/delete, Apple/Google sign-in and remaining team activity are explicitly unfinished, not covered by the completed membership slice | See commit history |
| 2026-10-20 | Core QoS pass: replaced team/roster/invite previews with persistent per-profile memberships, private/public teams, public prefix discovery, parent/coach approvals, rotating player codes and separate 24-hour single-use assistant-coach invites. Added mobile invite URLs and copy/share, account-creation recovery, invite continuation through authentication, stale-profile filtering and an unfinished-workout switch guard. Account deletion now cleans team memberships/requests/codes and preserves teams with another coach; deletion markers prevent new joins/profiles during cleanup. Approved coach-only team names; no player-authored content. All checks pass (350 Flutter, 60 Functions + 9 catalog, 54 emulator, 43 rules, native iOS E2E, Android debug build). Scoped backend/rules deployed with approval; no production account/team mutation probes | See commit history |
| 2026-10-20 | Phase 8 purchases and entitlements. App: `purchases_flutter` + `purchases_ui_flutter`; `lib/features/commerce/` holds the store connection (RevenueCat in production, an unavailable stand-in in tests), a plan on the account unlocks Pro for it and every profile it owns, and a paired kid device is Pro when the server flags its profile. The old hand-built paywall is replaced by RevenueCat's paywall (edited in its dashboard); the app wrapper handles guests, owners (manage, restore) and no-store states. Me, Parent Account and the Subscription sheet show the real plan and a real restore. Android uses a fragment activity and AppCompat theme for the paywall. Server: `revenueCatWebhook` (deployed, secrets in Secret Manager) re-reads the account from RevenueCat on every event and writes `users/{uid}.entitlements` and `pro` on each owned profile; new profiles inherit the plan. RevenueCat: Android app, four Play products attached to entitlements and packages, webhook registered, two AI-built paywalls published (rink graphic, no photos of people; Terms = Apple standard EULA, Privacy = https://howtohockey.com/privacy, which must exist before launch). Tests: 339 Dart, 60 Functions unit, 43 emulator. Not done: Play service-account validation still failing in RevenueCat (Google propagation), sandbox purchase on a device, server-side saved-routine cap, Coach Pro gating, Signature Programs, team grant | See commit history |
| 2026-10-20 | Phase 8 store setup, part 3. Apple: In-App Purchase key generated by the Account Holder login (key ID P73W9568TZ, `.p8` stored outside the repo with the other keys). RevenueCat (project `2f8111b3`): iOS app `com.howtohockey.app` connected with that key; four iOS products imported by ID; entitlements wired (`player_pro` ← all four products, so Coach Pro includes Player Pro; `coach_pro` ← the two coach products); offerings `player` (default: monthly + annual) and `coach` (monthly + annual). Public iOS SDK key `appl_OeNEuTtPsolnKkVomQlwOKdSGwT` (public by design, safe in the app). Google: service account `revenuecat-play@how-to-hockey.iam.gserviceaccount.com` created (Pub/Sub admin, Monitoring viewer) with its JSON key in the keys folder; Play Console would not let this login invite it (unexpected error), so the Android app in RevenueCat is waiting on a Play owner adding it with View app information, View financial data and Manage orders and subscriptions | See commit history |
| 2026-10-20 | Phase 8 store setup, part 2. Play Console: created an upload keystore (`how-to-hockey-upload.jks`, kept with the other app keys outside the repo; `android/key.properties`, git-ignored, points at it), added `purchases_flutter` (adds the billing permission Play needs), built the signed release bundle, uploaded it to Internal testing as a draft, and created and activated four subscriptions (`player_pro_monthly` $7.99, `player_pro_yearly` $49.99, `coach_pro_monthly` $12.99, `coach_pro_yearly` $99.99, USD with automatic local prices). Parents: one Player Pro or Coach Pro subscription on the parent account already covers the parent's own profile and every child profile it owns (up to 3), so no separate family product is planned; the paywall will say so. Next: Apple IAP key (Account Holder), Google service credentials, RevenueCat apps/products/offerings | See commit history |
| 2026-10-20 | Phase 8 store setup (no code yet). App Store Connect: app "How To Hockey" (Apple ID 6824994219, `com.howtohockey.app`) with subscription group "How To Hockey Pro" and four auto-renewable products (`com.howtohockey.app.player_pro_monthly` $7.99, `player_pro_yearly` $49.99, `coach_pro_monthly` $12.99, `coach_pro_yearly` $99.99; all countries, other currencies auto-equalised, English (U.S.) names). They still need review screenshots and must ship with the first app version. Play Console: app created (`com.howtohockey.app`, free); subscriptions stay locked until a signed build is uploaded. RevenueCat: new project "How To Hockey" (`2f8111b3`) with entitlements `player_pro` and `coach_pro`. Blocked: the App Store Connect In-App Purchase key needs an Admin/Account Holder (this login cannot open Integrations), and the Account Holder must accept the updated Developer Program License Agreement | See commit history |
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

## 🎯 Product Direction & Redesign Requirements (2026-10-21)

> **Status: requirements recorded from the user; fit assessment and redesign order NOT yet done or approved.** This section is the yardstick. At the start of any UX, navigation, workout, team or monetization work, re-read it, then record how the current app measures up in the *Fit Assessment* table below. Nothing here overrides a locked decision (see *Tensions*); where it conflicts, ask the user and record the outcome under Resolved Decisions.

### The five fundamentals (user's words, condensed)
1. **Training sessions are the core.** Workout tracking is the app's core function; everything else exists to get someone into a session or to make it better.
2. **The promise is "get a better ____"** — shot, hands, speed, explosiveness — with the heartbeat **"get better at hockey, and have fun doing it."**
3. **The active session must be foolproof for kids.** A disproportionate share of users on this screen are kids of many ages. It must be very visual, with clear instruction (video) and prominent action buttons.
4. **Coach → Parent → Player is the growth engine.** It must be well thought out and designed: coaches can create and share a routine with the team with little effort; parents can create and modify workouts for their kids; parents can correctly enter or update/correct a session's training time for their kids.
5. **The subscription's material value is tailored programs and routines/drills.** Each program targets a key pain point (harder shot, better accuracy, …) and mixes drills, exercises and challenges so it stays fresh and fun for kids.

**Overriding design test:** *easy to understand, simple to take ACTION and start guided training.* Every screen answers "what do I do next?" with one obvious primary action. (Complements the earlier principle: show the minimum crucial information per screen, with clear drill-down for detail.)

### Requirements by fundamental
Unchecked boxes are requirements to be assessed and scheduled, not committed scope.

**A. Outcome-first entry ("get a better ___")**
- [x] Home/Train leads with outcomes a player recognises (*Get a harder shot*, *Better accuracy*, *Quicker hands*, *Faster, more explosive*) and one primary **Start** action; setup, focus sliders and routine tuning become optional drill-downs, not prerequisites. *(Done 2026-10-21: six outcome buttons, hero **Start workout**, a "Customize" section.)*
- [x] A default "start now" path that needs zero decisions (sensible routine from last setup / current program day), reachable in ≤ 2 taps from app open. *(Train → Start workout = 1 tap; a workout under way shows **Resume workout** instead of replacing it. "Current program day" waits for R4.)*
- [x] Map outcomes to the existing six skills (Accuracy, Hands, Power, Passing, Speed/Strength, Endurance) — e.g. *harder shot* ≈ Power, *explosiveness* ≈ Speed/Strength — without losing the Skill Radar/progress model. *(`lib/features/coach/outcomes.dart`: an outcome puts 55 of the 100 focus points on its skill; derived from the focus, so hand-tuning the sliders never leaves a stale choice.)*
- [ ] Fun is designed in, not bolted on: variety between sessions, short challenges, visible progress and celebration suited to kids (no player-authored content).

**B. Kid-proof active session**
- [ ] The active drill screen is **video-led**: the demo is the hero, with short plain-language instruction (and spoken/visual cues for non-readers), large pictorial steps.
- [ ] **One prominent primary action** at a time (Start / Done / Next), large touch targets (confirm minimum size, e.g. ≥ 56 dp), thumb-reachable, hard to mis-tap; destructive/secondary actions are out of the way.
- [ ] Guided flow: the app tells the player what to do now and next (auto-advance, countdown, rest cues, haptics/sound), rather than expecting them to manage a table.
- [ ] Age-appropriate by design (young non-readers through teens): minimal text, icons, readable at arm's length, forgiving input (easy undo, no data-entry traps), works with sweaty/gloved hands and in a garage or rink.
- [ ] **Simple view is the default; Standard view is a toggle** (decision 1). Decide how the dense Hevy-style list and the focus view map onto the two modes. *(Decided 2026-10-21; build in R2.)*
- [ ] Never lose a session: offline-first, resume after interruption (already a principle).

**C. Coach → Parent → Player loop**
- [ ] **Coach:** build a routine from catalog drills (or pick a program day) and **share it with the whole team in a few taps**; players/parents see it on arrival with a clear "Start" and due date; completion is visible to the coach. Easy for a volunteer coach who is not technical.
- [ ] **Parent:** create and modify workouts for each child (from drills, routines, programs, or what the coach assigned); manage several kids without friction; see what each child has done and what is assigned.
- [ ] **Parent time correction:** a parent can enter a session for a child who trained without the app, and correct/update any session's training time, with an auditable record (who changed what, when). Adjusted sessions are **not** automatically excluded from leaderboards (decision 3).
- [ ] **Parent confirmation:** a child's finished session is saved only after a parent confirms it, on the same device or from another device (decision 2).
- [ ] **Player/kid:** opens the app and sees "your next thing" — assigned routine, program day or suggested session — and starts it.
- [ ] Invite/join stays one-link simple (already built: team codes, `howtohockey://app/join`); design the *first-run* experience for a child or parent arriving from a coach's link so they land on something to do.
- [ ] Notifications that close the loop (assigned, due soon, completed) — respecting child-safety/privacy rules.

**D. Programs and tailored routines (the paid value)**
- [ ] Programs are organised by **pain point** (harder shot, better accuracy, quicker hands, explosiveness, …), each a multi-week plan of varied days: drills, exercises and **challenges**, with video lessons where useful (Phase 12).
- [ ] Variety by design: rotation/substitution so repeated weeks don't feel the same; fresh challenge formats; progression suited to age/level.
- [ ] "Tailored" **means skill-targeted program content, not per-user personalisation** (decision 5); keep the existing setup + 100-point focus generator for free routines.
- [ ] Clear free vs paid boundary and an honest storefront/preview; a free taste of each program so value is obvious before paying. Parent subscriptions cover their children (already decided).
- [ ] Content pipeline is a dependency: real video demos, program days and challenge catalog (Phases 2, 12, 13). Placeholder media currently stands in.

### Fit Assessment (to be completed — start here next session)
| Requirement area | Where the app is today (honest, as of 2026-10-21) | Gap / question | Likely phases |
|---|---|---|---|
| A. Outcome-first entry | Train tab is a setup-and-focus flow (location, pucks, ball, passer, length, six-skill sliders) → generated routine → Start. | Not outcome-led; many decisions before Start; no "start now". | 5, UX-first |
| B. Kid-proof session | Default is a scrolling list with Hevy-style numeric set rows; one-drill **Focus view** has timer/counter, drill details with placeholder video behind a small icon. Buttons are standard size. | List is data-entry oriented (good for parents/advanced), not video-led or foolproof for young kids; instruction is not primary; no spoken/pictorial guidance. | 3, UX-first, 13 |
| C. Coach → Parent → Player | Teams, join codes, parent approvals, assistant-coach invites, coach roster/settings exist. Routine builder (local), saved routines (device only, free cap 3), Repeat/Save-as-routine from history. **Not built:** team routine sharing/homework, compliance, parent-created routines for a child, parent-entered or corrected sessions, assignment surfaces for players, notifications. | The loop's core actions don't exist yet; routines are device-local, not per-profile/cloud/shared. | 9, 10, 11 |
| D. Programs | Starter catalog (≈20 drills, placeholder video), generator, local routines. Phase 8 purchases partly built; Signature Programs, entitlement gates and challenges **not built**. | No program model, no pain-point organisation, no variety/challenge mechanics, minimal content. | 8, 12, 13 |
| Cross-cutting | Design system, offline-first sessions, no-UGC rule, kid-device sign-in, parent profiles (≤3 kids). | Age-appropriate UX standards and a kid-usability test method are not defined. | 3B–3G |

### R0 Findings (2026-10-21)
**Method.** Visited every reachable screen as a guest on the iPhone 16 Plus simulator (local emulators) and captured screenshots: Welcome, Train, Setup, Focus, Routine, Library, Drill detail, Programs, Progress, Team, Me, active session (list and focus view). Parent and Coach screens are gated (a guest is redirected to *Create account*), so those were assessed by reading `parent_pages.dart`, `coach_pages.dart`, `coach_state.dart`, `team_pages.dart`, routing and repositories. Not assessed: Android visuals; any real child's use (no user testing yet).

**Scorecard** (🟢 meets the intent · 🟡 partly · 🔴 misses or missing)
| Screen / flow | Verdict | Evidence |
|---|---|---|
| Welcome | 🟢 | One clear promise ("Feel more confident in your next game"), one primary *Get started*; secondary: account, kid's device, look around. Not yet "get a better ___". |
| Train (home) | 🟡 | Strong hero card with one red button, but it says **View workout**, not Start, and the hero ("A balanced workout") names no outcome. Below it: setup chips, *Build a workout*, *Manage routines*, drill list, Shot logger, Timer — equal-weight options competing with the start action. |
| Setup (5 questions) | 🟡/🔴 for kids | Location, pucks, ball, passer, length. Jargon ("Green Biscuit", "Rebounder") and many choices before value. Fine for a parent once, wrong as a gate each session. |
| Focus (100-point sliders) | 🔴 for kids | Abstract mechanic; good power-user/coach tool, not an entry point for a child. |
| Routine preview | 🟢/🟡 | Clear **Start workout**, *Try another*, *Save*; but it is the second step after *View workout*. |
| Drill library | 🟡 | Text list; no thumbnails; filters locked behind Pro; banner says video demos are coming. |
| Drill detail | 🟡 | Layout is right (video is the hero, cues numbered, **Try this drill**), but the hero is a "VIDEO SOON" placeholder — no real demo exists yet. |
| **Active session — list view** | 🔴 for kids | Dense numeric table; set fields are 40 dp and the ✓ is 44×40 dp (below the theme's own 48 dp minimum, far below a child-friendly target); no video or instruction visible; requires typing numbers. Good for a parent/advanced user. |
| **Active session — focus view** | 🟡 | Best fit today: one drill, big counter, big Log set. But the demo is behind a small ▶ icon, instruction text isn't shown, previews are tiny 9:16 cards with 11 pt labels, *Swap drill*/*Start rest* are small text buttons, and "Hits out of 10 · 0 · − / +" assumes the child can count and enter hits. |
| Programs | 🟡 | Titles are already pain-point shaped ("30 Days to a Harder Shot", "Elite Hands in 21 Days") with day progress and prices — right idea — but **buried under Me → Programs**, built on `SampleProgram` example data, "VIDEO SOON" media, not connected to purchases, routines or the session. |
| Progress | 🟢/🟡 | Honest, simple (shots logged, week bars, blurred skill map for non-Pro). Not motivating for a child (no fun/reward layer). |
| Team (player) | 🟢 | Honest guest state, join by code/public team, real memberships. No feed/homework/standings. |
| Me | 🟡 | Settings plus mode switching, programs, billing, sample "welcome preview" entries; a catch-all, not a place for "what next". |
| Parent: kids list / child page | 🟡 | Real: add child (≤3), **Train as …**, manage teams, pair kid device, approvals. Fake/missing: *Verify workouts* is a preview, *Hide from leaderboards* resets on restart, **no way to create/modify a workout for a child, assign one, see their history, or enter/correct session time.** |
| Coach: roster / requests / team | 🟡 | Real team creation, join codes, assistant-coach invites, roster, requests, public/private. |
| Coach: homework / compliance / assign | 🔴 | **Example data only** ("Wrist Shot Ladder · 3 of 5 done"); not connected to a roster, routines or players. No way to share a routine with a team. |

**Taps to start training (measured from the code/flow):** returning player with a setup — Train → *View workout* → *Start workout* = **2 taps**, then the session opens collapsed/expanded; from a program — Me → Programs → program → *Continue · Day n* → day screen → (start flow not wired) = **≥ 4 taps and not actually launchable**; a child on a parent's phone — Me → switch player → Train → 2 taps; coach-assigned work — **no path** (feature missing). Target in the requirements: ≤ 2 taps from open, none of them decisions.

**Findings by fundamental**
1. **Session-centred (strong base, wrong emphasis).** Engine quality is good: offline-first, wall-clock timers, persistence, editing, per-profile results, tests. But Train spends its first screen on setup/focus configuration and routine management rather than a single Start.
2. **"Get a better ___" (missing).** Language exists in the Focus screen ("Build a better session") and in Program titles, but nothing on Train lets a player choose an outcome and go. The six pillars map cleanly to outcomes, so this is a presentation/preset layer over the existing generator, not a new engine.
3. **Kid-proof session (biggest gap).** The user-facing surfaces I built on 2026-10-20 are optimised for logging numbers (Hevy/MacroFactor model). Missing for children: a video-first drill screen, spoken/pictorial instructions, ≥ 56–64 dp primary actions, one action at a time, auto-advance, no-typing capture (tap-to-count, done/not done, parent-confirmed), celebration. Real video content does not exist yet (placeholders), which caps the value of any redesign until Phase 13 content lands.
4. **Coach → Parent → Player (core actions absent).** Membership plumbing is solid; the *work* that flows through it is not. Prerequisites: routines/assignments must become **cloud, per-profile, shareable objects** (today routines live in `SharedPreferences` on one device, free cap 3), plus assignment/notification and an audited session-correction path. This is the largest engineering item and it gates R3.
5. **Programs (idea present, not real).** Program catalogue, day screens and pricing exist as an example data model. Missing: server-owned program definitions, pain-point taxonomy, the day → routine → session link, challenges/variety mechanics, entitlement gating, and content. The user now treats this as the paid value, which argues for moving it ahead of other Phase 8–12 items.

**Recommended order (for the user's decision)**
1. **Decide the session model** (see questions): guided visual flow as the default, current list as a parent/advanced view.
2. **Outcome-first Train + one-tap Start** using existing generator presets (quick win, mostly UI).
3. **Kid-proof guided session** (R2) with the video slot designed for real footage; tap-based inputs and big targets; test with real children.
4. **Cloud routines/assignments data model** (R3 foundation) → coach share-to-team → parent create/modify/enter-time with audit → player "your next thing".
5. **Programs** (R4) once content exists: server model, day → routine → session wiring, challenges, gating.
6. Keep Phase 8 purchase verification on a short parallel track since it gates any paid Programs.

**Decisions asked in R0** (answered by the user on 2026-10-21; see *Decisions and design consequences* below and Resolved Decisions)
- Is the guided, video-led flow the default for **everyone**, or do kids/parents choose (e.g. parent sets "Kid mode" per child profile)?
- Which age bands must the guided session serve (e.g. 6–8, 9–12, 13+), and should young non-readers get **spoken** instructions (voice-over audio)?
- How should a **child enter results** without typing — tap-to-count, "done/not done", honour-system sets, or parent confirmation?
- **Time correction:** may parents edit any session's time, or only add a manual session? Do adjusted/manual sessions count toward team leaderboards and PRs?
- **Free vs paid in the loop:** is "coach shares a routine with the team" free? Does the 3-saved-routines cap apply to coach/parent-created routines?
- What does **"tailored"** mean for a program (goal only, or also age, level, equipment, time)?
- Should Programs move ahead of remaining Phase 8/9 work, and is there a filming/authoring schedule for demo video and program days?
- Should guests be able to **preview** the coach and parent experiences before signing up (today they are redirected to *Create account*)?

### Decisions and design consequences (user answers, 2026-10-21)
| # | Decision (user) | Design consequences / proposals (assistant — confirm when building) |
|---|---|---|
| 1 | **Guided flow is the default** for everyone, because it is simply an easier way to train. Offer a **toggle between "Simple" (guided) and "Standard" views.** | Simple view = video-led, one action at a time, big buttons, tap-only inputs. Standard view = the current scrolling set list (and focus view features) for those who want numbers. Reuse the existing remembered-view preference (`workoutFocusView`), renamed/reworked; default flips to Simple. The standard list must still meet minimum touch-target sizes. **Answered 2026-10-21:** anyone using the app is expected to read basic buttons and actions, so **no age bands and no voice-over** are required (keep copy short and icons clear; spoken instructions are not scoped). |
| 2 | **Kids enter results with simple buttons. A parent confirms the entire workout/session before the final save.** Must work on a **single device and multiple devices.** | New session state **pending parent confirmation** between "kid finished" and "saved/credited". Single device: finishing leads to a *Hand to a grown-up* review screen (every drill/set, edit allowed, **Confirm & save**); multi-device: the kid device uploads a pending draft under the child profile, the parent device gets a *Review* item (+ push) and confirms. Server credit (`onSessionCompleted`, stats, PRs, sync) must move from "on create" to "on confirm". Offline: pending drafts persist locally and sync when online. Kid input = tap-to-count (+/−), done / not done, quick number pads — no keyboard. **Answered 2026-10-21:** (a) Teens (and anyone) with their **own account** simply use it, untethered from a parent account — confirmation applies only to **child profiles managed by a parent**; no parent is required where billing allows (their own subscription). The user does not want age-based verification or behaviour restrictions (see the age-gate flag in *Tensions*). (b) An unconfirmed session **stays pending** (parent reminded, never auto-credited). (c) A kid **can see their own result before confirmation**, marked "waiting for a grown-up". |
| 3 | **Parents can manage anything their kid does in the app.** Honouring the team (leaderboards etc.) is on parents and coaches. | Resolves the leaderboard-integrity tension by policy, not code: parents may edit/add/delete a child's sessions and adjust time, with an **audit trail** (who, when, what changed) kept server-side but **no automatic exclusion** from leaderboards/PRs. Parent controls cover routines, assignments, sessions, time, team membership, visibility. Corrections go through a callable and a correction-capable session model (sessions are no longer write-once for parents; coach/other players cannot edit). |
| 4 | **Coach can share one routine with the team for free** ("one active free routine at a time"). The **3-saved-routines cap applies to every non-subscriber.** | Team has a single `activeRoutine` (catalog drills + sets, no free text) visible to rostered players/parents as "Coach's routine" with Start; replacing it archives the previous one. Multiple active routines/assignments with due dates, compliance, etc. stay **Coach Pro** (Phase 11). Saved-routine cap (3) stays per profile/account for free users; a coach's one active team routine does not count toward a player's cap (proposed) but a coach's own *saved* routines do. Pro lifts the cap. |
| 5 | **"Tailored" = the program material is targeted at the marketed skill** (e.g. *harder shot*), **not personalised to the user.** | Programs are fixed, skill-targeted content sets (drills, exercises, challenges, lessons). No per-user generation, level or age logic needed for Programs; simplifies the data model and server work. Pain-point/outcome taxonomy maps to the six pillars. |
| 6 | **Programs are a key part of the app; build UI and functionality now with placeholder video/content** (no filming yet). | Move Programs ahead of other Phase 8–12 items: server-owned program model, day → routine → session wiring, challenges, free taste, entitlement gating, storefront — all with placeholder media (placeholder rule stays: "PLACEHOLDER VIDEO · REPLACE BEFORE LAUNCH"). |
| 7 | Make it **clear from the first screens that the app serves player, parent and coach**, with a **preview in a landing screen/walkthrough.** | First-run walkthrough (also reachable later) showing the three roles with real-looking previews of each (player session, parent confirm/manage, coach share-to-team). Replaces redirecting guests straight to *Create account* from role screens with a preview. Fits the existing role-onboarding screens and "Look around first". |

### Tensions with existing decisions (**resolved by the 2026-10-21 answers unless marked OPEN**)
- **Parent time correction vs "server is source of truth" / immutable session writes / leaderboards ranked by active time.** Corrections need a server-side callable, an audit trail, and a rule for whether adjusted/manual time counts toward team leaderboards and PRs (e.g. flagged `adjustedBy: parent`, excluded or labelled). Today session docs are write-once and credit is computed server-side.
- **Coach/parent routine sharing vs "No UGC" — user decision 2026-10-21:** routine names are set **at the program level**, or **parents/coaches may name their own custom routines freely (character-limited)**. This is a deliberate extension of the approved coach-team-name exception: **only adults managing a team/child author names; players/kids never type free text.** Names are visible to the players they are shared with, so build: server-side validation (length cap, e.g. ≤ 40 characters; no control characters/markup, like team names), and consider a profanity filter and a report path because App Store/Play review treats user-created text shown to others as UGC (App Review Guideline 1.2). No free-text instructions, descriptions, photos or video. Record the exact cap when implemented.
- **Age rules vs "no age-based restrictions" — RESOLVED 2026-10-21.** The user chose to **keep the existing self-declared (unverified) age gates** because they improve the user experience: the birth-year gate (under-13 directed to a parent-created child profile) and the 19+ rule for creating teams/accepting coach invites. No new age verification or age-based restrictions will be added.
- **Monetization gating of the loop.** Phase 11 puts the custom routine builder, homework and compliance in **Coach Pro**, and the free tier caps saved routines at 3. The growth loop wants "easy for coaches" — decide what is free (e.g. share a simple routine) vs Pro (compliance, rosters > N), and whether parent-created workouts are limited by the cap.
- **Guided kid flow vs Hevy-style list (just built, 2026-10-20) and the earlier MacroFactor-style direction.** Resolved-decision history favours swipe-through drills and an overview; the user now prioritises kids and video. Likely outcome: guided visual flow as default, dense list as an optional/parent view — to be confirmed.
- **Video-led instruction vs content readiness.** All demos are placeholder stand-ins; the experience can be designed now but final value depends on filming (Phase 13).
- **Programs timing.** Signature Programs are Phase 12 and outside the Suggested MVP Cut; the user now calls them the main subscription value. May warrant re-ordering ahead of other Phase 8–11 work.
- **Phase order.** The UX-first/redesign work may supersede the planned order (Phase 8 purchase verification, remaining Phase 9 feed/standings). Needs an explicit decision; Phase 8 verification items remain open.

### Redesign track (scheduled 2026-10-21; order is the proposed build order, confirm before starting each)
- [x] **R0 – Fit assessment:** done 2026-10-21 (see *R0 Findings*); user decisions recorded above.
- [~] **R1 – First run & entry (2026-10-21, uncommitted):** **Done:** first-launch **welcome walkthrough** previewing Player / Parent / Coach (swipeable; what works is ticked, what is coming is marked *Soon*; opens by itself once via `initialLocationProvider` + `welcomeSeen`, skipped for signed-in accounts; still reachable from Me); **outcome-first Train** with one **Start workout** / **Resume workout** action. **Remaining for R1:** role-aware "your next thing" (coach's active routine, program day, suggested session) — needs R3/R4 data; guests still can't preview the real parent/coach screens (the walkthrough is their preview); check the Train layout on a small phone (Start sits below six outcome buttons); outcome selection could also become a program entry point in R4. Tests: `test/app/entry_flow_test.dart` (12). Visual walkthrough: `integration_test/first_run_visual_test.dart`.
- [ ] **R2 – Simple (guided) session + Standard toggle:** video-led, one-action-at-a-time guided flow as the default; tap-only kid inputs; ≥ 56 dp primary actions; Standard view = today's list; both views meet touch-target minimums. Includes the **pending-parent-confirmation** session state and *Hand to a grown-up* review on one device (decision 2).
- [ ] **R3 – Cloud routines & the Coach → Parent → Player loop:** routines become cloud, per-profile, shareable objects; coach shares **one active team routine** free (decision 4); parent creates/modifies workouts and sessions for each child with audit, including time correction and multi-device confirmation queue + push (decisions 2–3); player sees the assignment on Train.
- [ ] **R4 – Programs & challenges (pulled forward):** server-owned skill-targeted programs with placeholder video/content, day → routine → session wiring, challenge/variety mechanics, storefront, free taste, entitlement gating (decisions 5–6). Phase 8 purchase verification runs in parallel because it gates paid Programs.
- [ ] **R5 – Content (later):** film demos and lesson videos, author real program days and challenges — replaces placeholders; not scheduled.
- [x] **Open questions from R0 resolved 2026-10-21:** no age bands/voice-over; own-account users untethered and exempt from parent confirmation; unconfirmed sessions stay pending; kids see pending results; routine names come from programs or are free-text but character-limited when created by parents/coaches. **All R0 questions are now answered.**

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
- [x] **Shared device alternative:** on the parent's device, Player mode has a "Switch Player" picker for the parent's child profiles (optionally PIN-protected exit back to Parent/Coach mode) *(Picker is live and device-local. Stale profiles are excluded across account changes; finish the active workout before switching. Optional PIN protection is not implemented.)*
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
- [x] App Store Connect / Play Console products *(subscriptions created on both; Signature Programs one-time products are still to do)*:
  - Player Pro: monthly $7.99, yearly $49.99
  - Coach Pro: monthly $12.99, yearly $99.99
  - Signature Programs: non-consumable IAPs $14.99–$39.99, plus discounted variants (−20%) for Pro subscribers
- [x] RevenueCat: entitlements `player_pro`, `coach_pro` (`program_<id>` with the Programs work); offerings `player` and `coach`, each with a dashboard-edited paywall
- [x] RevenueCat webhook → Cloud Function → write `users/{uid}.entitlements` and a `pro` flag on every profile the account owns *(deployed; custom claims not needed since profiles carry the flag)*
- [ ] Firestore/Storage rules read entitlements (Pro drill media, Pro analytics endpoints)
- [ ] **Effective Pro for a profile** = owner account has `player_pro` or `coach_pro` **OR** `profile.teamProGrant.expiresAt > now` **for that profile only** (a grant never extends to the owner account or sibling profiles); single resolver shared by client (UI gating) and rules/Functions (enforcement)
- [x] Paywall: RevenueCat's own paywall (wording and plans editable in its dashboard, no app release), wrapped by the app for guests (create an account first), owners (manage and restore) and kid devices *(real purchase flow not yet exercised on a device)*
- [ ] Program discount: show discounted product ID only when `player_pro` is active
- [ ] `coach_pro` entitlement **includes all `player_pro` features** (configure in RevenueCat: Coach Pro products grant both entitlements)
- [ ] Sandbox/test-track purchase testing on both platforms

**Exit Criteria:** Purchasing unlocks features on both platforms; cancel/expire revokes them.

---

## Phase 9 — Teams & Locker Room Feed
- [x] Create team (Coach mode) → join code + deep link invite; visibility **private** (default) or **public** *(Core callables and rules deployed; iOS URL handoff tested, Android URL filter builds. Player code rotation revokes old links. Assistant coaches use a different, single-use code that expires in 24 hours.)*
- [x] **Membership is per player profile**, never per account. A parent can place each child on the same or different teams; one child can be on multiple teams
- [x] Join flow: open invite/code → choose which profile joins (own profile or a child) → joined
  - From a kid device → creates a `joinRequest` the parent must approve in Parent mode
- [ ] **Public team discovery:** prefix search over `teamDirectory`; card shows team name, coach display name, player count, and generic team stats (e.g., weekly team training hours, sessions) → "Request to Join" → coach approves *(Search, safe directory cards and approval flows are built; aggregate training stats remain deferred with team activity.)*
- [x] `teamDirectory/{teamId}` is a separate doc maintained by Functions (Firestore rules can't hide individual fields, so the private `teams` doc is never publicly readable); removed when a team goes private
- [x] Coaches cannot search for or invite individual players (no player directory)
- [x] Leaving/removing: parent or coach can remove a child from a team; player data stays with the profile
- [ ] Function `onSessionCompleted` → writes system feed post:
  `[Player Name] completed [Routine] • [Key Metric] • [Streak: N Days]`
- [ ] **Stick Tap:** one per profile per post (`taps/{profileId}` doc; count via Function or `FieldValue.increment`)
- [ ] **Ranked leaderboard = active training time only** (weekly / monthly / all-time), materialized by Function from `activeSeconds`. Equal footing for Free, Pro, and program owners, and it can't be inflated by idle timers (see Phase 6 caps)
- [ ] Non-ranked team stats shown alongside (total team shots, sessions, longest streak) for flavor
- [ ] Leaderboards and feed are visible **only to team members**, including on public teams (public = discoverable card only)
- [ ] Verified checkmark display on feed and leaderboard
- [ ] FCM push: stick taps received, new homework, verification
- [ ] Rules: feed/leaderboards read-only to clients except tap docs; only team members (or the parent/coach of a member) can read `teams/**`; `teamDirectory` is readable by any signed-in user
- [x] No player-authored team content or uploads. Coach-only team naming and non-published code/search inputs are allowed by the approved 2026-10-20 exception.

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
- **Age gates kept (2026-10-21, user-approved):** The existing self-declared, unverified age gates stay (under-13 → parent-created child profile; 19+ to create teams/accept coach invites) because they improve the experience; no further age verification or age-based restrictions will be added. Routine-name free text (adult authors, character-limited) was approved the same day.
- **R0 follow-up answers (2026-10-21, user-approved):** No age bands or voice-over: anyone using the app can read basic buttons. Anyone with their own account (including teens) uses it untethered from a parent account (no parent where billing allows); parent confirmation applies only to child profiles a parent manages. Unconfirmed sessions stay pending; kids see their pending results marked "waiting for a grown-up". Routine names come from the program, or parents/coaches may name custom routines freely within a character limit — an **intentional exception to No-UGC** (adult authors only; kids never type free text), extending the coach team-name exception. The user does not want age-based verification/behaviour restrictions; existing age rules (under-13 gate, 19+ coach) are flagged in the roadmap and stay until the user confirms.
- **R0 answers (2026-10-21, user-approved):** (1) The guided "Simple" session is the default for everyone, with a toggle to the "Standard" view. (2) Kids enter results with simple buttons; a **parent confirms the entire session before the final save**, on a single device or across devices. (3) Parents may manage anything their kid does in the app (sessions, time, routines, team membership); honouring team leaderboards is on parents and coaches — no automatic exclusion, but changes are audited. (4) A coach can share **one active routine with the team for free**; the **3-saved-routines cap applies to every non-subscriber**. (5) "Tailored" means program content targeted at the marketed skill, not personalised per user. (6) Programs are a key part of the app and are built now with placeholder video/content (no filming yet). (7) The first screens must make clear the app serves player, parent and coach, with a preview in a landing screen/walkthrough. Consequences and open questions: *Product Direction & Redesign Requirements → Decisions and design consequences*. Supersedes, for the redesign, the earlier workout-view decisions that favoured the swipe/overview model; supersedes Phase 6's "credit on create" (credit moves to confirmation for child profiles).
- **Product direction recorded (2026-10-21, user requirements; fit assessment pending):** Core value is guided training sessions; the promise is "get a better ___ … and have fun"; the active session must be video-led and foolproof for kids; Coach → Parent → Player (team routine sharing, parent-created workouts, parent session time entry/correction) is the growth engine; paid value is pain-point Programs with varied drills/challenges. Recorded as requirements in **Product Direction & Redesign Requirements**; not yet approved as architecture changes. Conflicts with locked decisions are listed there for the user to resolve.
- **Core QoS priority and team naming (2026-10-20, user-approved):** Implement the missing core membership/invite flows ahead of unfinished monetization; leave team feed, standings, homework and purchases outside this pass. Coaches may enter a team name; players still cannot publish free text, photos or videos. Assistant coaches receive a separate single-use invitation expiring after 24 hours, not a player join code. Native invite URLs use `howtohockey://app/join?code=...`; installed-app handoff is supported, not a hosted web landing page.
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
