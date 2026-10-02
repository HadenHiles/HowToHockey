# How To Hockey — Build Roadmap (Flutter + Firebase, iOS & Android)

This roadmap turns the product spec into ordered, checkable milestones. Each phase ends in a shippable or testable state. Work top to bottom; do not start a phase until the previous phase's **Exit Criteria** are met.

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
| Media | Looping MP4 (H.264, muted, 3–5s) via `video_player` + `flutter_cache_manager`; long-form as progressive MP4 streamed from Firebase Storage via short-lived signed URLs | MP4 is far smaller than GIF; long-form volume is small, so no separate video provider |
| Audio | `just_audio` (chimes) + `audio_session` (mix with user's music) | |
| Wake/haptics | `wakelock_plus`, `HapticFeedback` | Screen stays on during sessions |
| Sharing | `RepaintBoundary` → PNG → `share_plus` | Native share sheet only |
| Local persistence | Firestore offline cache + `shared_preferences` for setup/focus presets | Garage/rink often has bad signal |
| Environments | Firebase projects: `howtohockey-dev`, `howtohockey-prod`; Flutter flavors `dev` / `prod` | |
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
  main_dev.dart / main_prod.dart
  app/                 # App widget, router, theme, flavors, role shells (player/parent/coach)
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
  shared/widgets/
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

## Phase 1 — Foundations
- [ ] `flutter create --platforms=ios,android --org com.howtohockey how_to_hockey`
- [ ] Add flavors (dev/prod), bundle IDs, app icons, splash
- [ ] Create both Firebase projects; run `flutterfire configure` per flavor
- [ ] Install core packages (Riverpod, go_router, freezed, Firebase SDKs)
- [ ] Enable Crashlytics, Analytics, App Check (DeviceCheck/App Attest + Play Integrity)
- [ ] Set up Firebase Emulator Suite (Auth, Firestore, Functions, Storage) for local dev
- [ ] `functions/` TypeScript project with ESLint and unit tests
- [ ] Theme: brand colors, typography, large touch targets (gloves/sweaty hands)
- [ ] CI: `flutter analyze`, `flutter test`, functions tests, rules tests on every PR

**Exit Criteria:** App boots on both platforms against emulators; CI green.

---

## Phase 2 — Drill Catalog & Content Pipeline
- [ ] Implement models in §2 with freezed + converters
- [ ] Define drill spreadsheet/JSON schema; write `tool/seed/` script to upload drills to Firestore and media to Storage
- [ ] Media spec: 3–5s MP4, 720p, muted, ≤1.5 MB, plus poster JPG
- [ ] Seed the **20 free starter drills** covering all 5 pillars and all 6 tracking types
- [ ] Drill Library screen: list, detail, looping media card, form cues
- [ ] Filters: location, puck inventory, ball type, passer, pillar, tracking type (filters are Pro-only per tier matrix; free sees the starter 20)
- [ ] Media caching and preloading of the next drill's video

**Exit Criteria:** All seed drills browsable offline after first load.

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
- [ ] Firebase Auth: Sign in with Apple (required on iOS when offering third-party login), Google, email/password
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
- [ ] Accessibility: dynamic type, contrast, VoiceOver/TalkBack labels on timers and inputs
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
- **Free-tier routines:** Free users can generate custom routines but may keep only **3 saved** at a time. *(Phase 5)*
- **Coach Pro includes Player Pro.** *(Phase 8)*
- **Child profiles on Free:** Free accounts can create and manage child player profiles. *(Phases 4, 10)*
- **Team Pro Month:** Rostered players on a Coach Pro team get 30 days of Player Pro. *(Phase 11)*
- **Skill Radar:** Absolute levels per pillar based on active training time. *(Phase 6)*
- **Leaderboards:** Team-only visibility; public teams are discoverable via search. Ranked metric is active training time only. *(Phase 9)*
- **Team membership:** Per player profile; parents manage children across the same or different teams. Player, Parent, and Coach modes are separate UI shells. *(Phases 4B, 9)*
- **Long-form video:** Firebase Storage with signed URLs. *(Phase 12)*
- **Team Pro Month scope:** Once per profile ever; only the rostered player profile receives it. *(Phase 11)*
- **Public teams:** Discoverable with name, player count, and generic team stats; feed and leaderboard stay members-only. *(Phase 9)*
- **Child devices:** Kid-device QR sign-in **or** parent-device profile switching. Siblings can train concurrently on separate devices or together via Group Session. *(Phases 4, 10B)*
