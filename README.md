# spec-to-ship

A Claude Code project template that takes you from a raw idea to shipped code — autonomously. Combines spec-driven development with the **Ralph Wiggum agentic coding loop** popularized by [Ryan Carson](https://x.com/ryancarson/status/2023452909883609111).

Two versions are available. Pick the one that fits your workflow.

---

## The Two Templates

### [`project-template/`](./project-template)
**The base version.** Spec-driven development + the Ralph agentic loop. No external project management dependencies. Everything lives in `docs/SPEC.md`, `prd.json`, and `git`.

Best if you: want to get started immediately, don't use Linear, or prefer keeping everything local.

### [`project-template-linear/`](./project-template-linear)
**The Linear-integrated version.** Everything in the base template, plus full two-way sync with your Linear workspace. Stories become Linear issues. The loop marks them In Progress and Done as it builds. Failures queue gracefully and retry automatically.

Best if you: already use Linear, want visibility into build progress without reading raw JSON, or are building with a team.

---

## How It Works

The problem with agentic coding loops is the task list going into them. If your stories are vague, over-scoped, or built on unverified assumptions about APIs and auth, the agent builds the wrong thing. This template solves that with a structured spec phase *before* any code is written.

The full pipeline:

```
💡 Idea  →  /spec-discovery  →  docs/SPEC.md  →  /spec-to-prd  →  prd.json  →  Ralph Loop  →  git log
```

**`/spec-discovery`** — Claude Code interviews you across 10 categories: the core problem, user roles, feature flows and edge cases, auth approach, data model, every external API and whether you've confirmed it works, your full tech stack, all required environment variables, and the risks most likely to derail the project. At the end it writes `docs/SPEC.md` directly to disk.

**`/spec-to-prd`** — Reads the spec and converts it into `prd.json`: a structured task list of properly-sized user stories with acceptance criteria, technical notes, and dependency ordering. Each story is sized to fit inside a single AI context window — no over-scoped tasks that cause the agent to drift.

**`/env-check`** — Audits your `.env.local` against every service the spec requires. Catches missing API keys, misconfigured Stripe test/live key mismatches, missing Prisma direct URLs, and other blockers before the loop starts.

**`./scripts/ralph/ralph.sh`** — The loop. Spawns Claude Code up to N times. Each iteration gets a fresh context window, picks the next incomplete story, implements it, runs your test command, commits to git, marks the story complete, and signals done. Based on the [Ralph Wiggum technique](https://github.com/snarktank/ralph) by Ryan Carson.

---

## What Makes This Different From Just Running the Loop

Most people discover the Ralph technique, set up the bash loop, and then struggle with the task list. They write stories like "build the dashboard" or "set up auth" — which are too large for a single context window and lead to partial implementations, hallucinated decisions, and broken tests.

This template enforces the discipline that makes the loop reliable:

- **Stories are sized correctly** — the `/spec-to-prd` command enforces a strict rule that each story is one deployable unit (one component, one endpoint, one migration, one auth step — not a whole feature)
- **Dependencies are explicit** — stories are ordered so nothing runs before its dependencies are met
- **The environment is verified first** — `/env-check` confirms every API key, webhook secret, and database URL is in place before a single iteration runs
- **The agent has institutional memory** — `progress.txt` accumulates learnings across fresh context windows, so later iterations benefit from patterns and gotchas discovered in earlier ones

---

## The Linear Version Adds

- **Automatic project creation** during `/spec-discovery` — Linear project, spec document, and MVP milestone created in one shot
- **Issues for every story** during `/spec-to-prd` — color-coded epic labels, acceptance criteria as checkboxes, `blockedBy` dependency wiring
- **Live status updates** during the loop — issues move from Todo → In Progress → Done as Ralph builds, with a comment on each containing the commit hash
- **Graceful failure handling** — if Linear MCP times out or drops, the update is queued in `linear-retry.json` and retried at the start of the next iteration and after the loop ends. The build never blocks on a connectivity issue.
- **`/linear-retry`** — manual flush command for clearing the retry queue when Linear comes back online
- **`/linear-sync`** — full reconciliation command if the two systems drift for any reason

---

## Quick Start

```bash
# Clone the repo
git clone https://github.com/[your-username]/spec-to-ship.git

# Copy the template you want
cp -r spec-to-ship/project-template/ my-new-app/
# or
cp -r spec-to-ship/project-template-linear/ my-new-app/

# Run setup
cd my-new-app/
./setup.sh my-new-app

# Open in Claude Code
claude .

# Start the discovery interview
# (Claude will interview you and write docs/SPEC.md automatically)
/spec-discovery

# When the spec feels right, generate the task list
/spec-to-prd

# Verify your environment
/env-check

# Build
./scripts/ralph/ralph.sh 20
```

---

## What's in Each Template

```
project-template/
├── CLAUDE.md                   Auto-loaded by Claude Code — phase tracker,
│                               stack info, conventions, open questions
├── .claude/
│   ├── settings.json           Permission allowlist for autonomous runs
│   └── commands/
│       ├── spec-discovery.md   /spec-discovery
│       ├── spec-to-prd.md      /spec-to-prd
│       └── env-check.md        /env-check
├── scripts/ralph/
│   ├── ralph.sh                The loop runner
│   └── CLAUDE.md               Per-iteration agent instructions
├── docs/SPEC.md                Product spec (generated by /spec-discovery)
├── prd.json                    Task list (generated by /spec-to-prd)
├── progress.txt                Append-only agent learning log
├── .env.example                All required env vars (no secrets)
└── setup.sh                    One-time setup script
```

The Linear version adds:

```
project-template-linear/
├── .claude/commands/
│   ├── linear-sync.md          /linear-sync — reconcile prd.json ↔ Linear
│   └── linear-retry.md         /linear-retry — flush the retry queue
├── linear-retry.json           Queue of failed Linear MCP updates
└── ...                         (all base template files, updated for Linear)
```

---

## Requirements

- [Claude Code](https://claude.ai/claude-code) — the CLI tool that powers the loop
- `jq` — for JSON parsing in the bash scripts (`brew install jq`)
- `git` — initialized in your project directory
- A test command that exits non-zero on failure (the loop won't mark stories complete otherwise)

For the Linear version:
- A Linear workspace with the Linear MCP connected to Claude Code

---

## Credits

The Ralph Wiggum agentic loop technique was developed and popularized by **Ryan Carson** (Builder-in-Residence at Amp).

- Original post: [x.com/ryancarson/status/2023452909883609111](https://x.com/ryancarson/status/2023452909883609111)
- Reference implementation: [github.com/snarktank/ralph](https://github.com/snarktank/ralph)
- Step-by-step guide: [x.com/ryancarson/status/2008548371712135632](https://x.com/ryancarson/status/2008548371712135632)

The spec-driven development workflow, slash command architecture, Linear integration, and retry queue system in this template were built to solve the upstream problem the Ralph technique assumes is already solved: having a well-defined, properly-scoped task list before the loop begins.

---

## License

MIT
