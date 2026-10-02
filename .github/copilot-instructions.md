# How To Hockey — Agent Instructions

- `ROADMAP.md` is the source of truth for scope, architecture, design system, and progress. Read its **Current Status** section before starting any work.
- Work the current phase's unchecked items in order. Check items off (`[x]`) in the same change that completes them.
- At the end of a session, update **Current Status** (phase, next task, blockers, date) and add a **Session Log** row.
- Do not change locked decisions (Architecture Decisions, Resolved Decisions, Design System) without the user's approval; record new decisions under **Resolved Decisions**.
- Flutter targets iOS and Android only. Use Riverpod, go_router, freezed; Firebase backend with Cloud Functions in TypeScript.
- UI must use design tokens from `lib/design/`. No raw colors or text styles in feature code. Brand primary `#CC3333`, font Inter.
- Never add free-text, photo, or video upload inputs for players (no UGC).
