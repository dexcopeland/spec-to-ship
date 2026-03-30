# Project: [PROJECT_NAME]
> This file is auto-loaded by Claude Code on every session. Keep it current.

---

## Current Phase

- [ ] Phase 1 — Discovery (run `/spec-discovery` to start)
- [ ] Phase 2 — Spec review & sign-off (edit `docs/SPEC.md` until it feels right)
- [ ] Phase 3 — Environment setup (run `/env-check`, fill `.env.local`)
- [ ] Phase 4 — PRD + Linear setup (run `/spec-to-prd` after spec is locked)
- [ ] Phase 5 — Build loop (run `./scripts/ralph/ralph.sh`)
- [ ] Phase 6 — Review & iterate (check `git log`, `prd.json`, Linear board)

**Check the box for the phase you're currently in.**

---

## Project Summary
> Fill this in after Phase 1 is complete.

**What it does:** [one sentence]
**Who it's for:** [target user]
**MVP scope:** [2-3 bullet points of what's in v1]

---

## Tech Stack
> Fill this in during Phase 1 discovery.

| Layer | Choice |
|-------|--------|
| Framework | |
| Database | |
| ORM | |
| Auth | |
| Styling | |
| Deployment | |
| Package Manager | |
| Test Command | `npm run typecheck && npm test` |

---

## Linear Workspace
> Filled in automatically by `/spec-discovery` and `/spec-to-prd`.

**Team:** [linear team name]
**Project:** [PROJECT_NAME]
**Project ID:** [filled by /spec-discovery]
**Linear URL:** [filled by /spec-discovery]
**Spec Document ID:** [filled by /spec-discovery]
**MVP Milestone:** [filled by /spec-to-prd]

---

## Key Files

| File | Purpose |
|------|---------|
| `docs/SPEC.md` | Full product specification (source of truth) |
| `prd.json` | Executable task list — each story has a `linearIssueId` |
| `progress.txt` | Append-only log of agent learnings per iteration |
| `scripts/ralph/ralph.sh` | Loop runner — spawns Claude Code per iteration |
| `scripts/ralph/CLAUDE.md` | Per-iteration agent instructions |
| `.env.example` | All required env vars (no secrets — committed to git) |
| `.env.local` | Actual secrets (NOT committed to git) |

---

## Available Commands

| Command | What it does |
|---------|-------------|
| `/spec-discovery` | Discovery interview → writes `docs/SPEC.md` + creates Linear project |
| `/spec-to-prd` | Converts spec → `prd.json` + creates Linear issues with epic labels |
| `/env-check` | Audits environment against spec requirements |
| `/linear-sync` | Reconciles `prd.json` passes status with Linear issue states |
| `/linear-retry` | Flushes `linear-retry.json` — retries Linear updates that failed during the loop |
| `./scripts/ralph/ralph.sh [n]` | Runs n iterations; auto-flushes retry queue each iteration and after the run |
| `./scripts/ralph/ralph.sh [n] --timeout [s]` | Same, with custom per-iteration timeout in seconds (default: 600) |

---

## Open Questions
- [ ] [Question] — blocking / non-blocking

---

## Codebase Conventions
> Fill in once the project is scaffolded. The Ralph agent reads this section.

- Components live in: `[path]`
- Server actions live in: `[path]`
- API routes live in: `[path]`
- Shared utilities live in: `[path]`
- Client-side env var prefix: `NEXT_PUBLIC_` (or equivalent)
- Import alias: `@/` maps to `./src/` (or `./`)

---

## Recent Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| | | |
