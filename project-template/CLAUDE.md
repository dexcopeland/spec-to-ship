# Project: [PROJECT_NAME]
> This file is auto-loaded by Claude Code on every session. Keep it current.

---

## Current Phase

- [ ] Phase 1 — Discovery (run `/spec-discovery` to start)
- [ ] Phase 2 — Spec review & sign-off (edit `docs/SPEC.md` until it feels right)
- [ ] Phase 3 — Environment setup (run `/env-check`, fill `.env.local`)
- [ ] Phase 4 — PRD generation (run `/spec-to-prd` after spec is locked)
- [ ] Phase 5 — Build loop (run `./scripts/ralph/ralph.sh`)
- [ ] Phase 6 — Review & iterate (check `git log`, update `prd.json`, re-run loop)

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

## Key Files

| File | Purpose |
|------|---------|
| `docs/SPEC.md` | Full product specification (source of truth) |
| `prd.json` | Executable task list for the Ralph loop |
| `progress.txt` | Append-only log of agent learnings per iteration |
| `scripts/ralph/ralph.sh` | Loop runner — spawns Claude Code per iteration |
| `scripts/ralph/CLAUDE.md` | Per-iteration agent instructions |
| `.env.example` | All required env vars (no secrets — committed to git) |
| `.env.local` | Actual secrets (NOT committed to git) |

---

## Available Commands

| Command | What it does |
|---------|-------------|
| `/spec-discovery` | Runs a structured discovery interview → writes `docs/SPEC.md` |
| `/spec-to-prd` | Converts `docs/SPEC.md` → `prd.json` task list |
| `/env-check` | Audits your environment against spec requirements |
| `./scripts/ralph/ralph.sh [n]` | Runs n iterations of the agentic build loop |

---

## Open Questions
> Questions that came up during discovery that need answers before or during development.
> Update this list as questions get resolved.

- [ ] [Question] — blocking / non-blocking

---

## Codebase Conventions
> Fill this in once the project is scaffolded. The Ralph agent reads this section.

- Components live in: `[path]`
- Server actions live in: `[path]`
- API routes live in: `[path]`
- Shared utilities live in: `[path]`
- Environment variable prefix for client-side: `NEXT_PUBLIC_` (or equivalent)
- Import alias: `@/` maps to `./src/` (or `./`)

---

## Recent Decisions
> Log major architectural or product decisions here so context isn't lost between sessions.

| Date | Decision | Rationale |
|------|----------|-----------|
| | | |
