# Spec-Driven Agentic Dev Template

A Claude Code project template that takes you from a raw idea to shipped code — autonomously — by combining spec-driven development with an agentic coding loop that runs while you sleep.

---

## Origin: The Ralph Wiggum Technique

This template is built around a technique popularized by **Ryan Carson** (Builder-in-Residence at Amp) in a widely-shared post on X. The core observation was deceptively simple:

> Give an AI agent a structured task list. Let it pick one item, implement it, run tests, commit the result, and repeat — autonomously — until the list is empty.

Carson named this the **Ralph Wiggum** technique, after the Simpsons character — embodying the philosophy of persistent, cheerful iteration despite the odds. The result: you wake up to a git log full of completed features.

The technique went viral because it worked. Not because it was magic, but because it enforced discipline: small, well-defined tasks, automated quality checks on every iteration, and a loop that couldn't drift because each iteration started with a completely fresh context window.

But there was a catch. The loop is only as good as the task list going into it. And most developers — jumping straight from an idea to a backlog — produce task lists that are vague, over-scoped, missing dependencies, or based on assumptions about APIs and integrations they haven't verified.

**That's the problem this template solves.**

---

## The Core Insight: Spec-Driven Development + Agentic Loops

The two halves of this template solve two distinct problems:

```
PROBLEM 1                          PROBLEM 2
─────────────────────────────      ─────────────────────────────
You start building and realize     You have a great spec but
halfway through that you missed    you're writing code yourself
a key feature, assumed an API      instead of reviewing what the
worked differently, forgot auth,   agent built overnight.
or built the wrong version of
something.
         ↓                                    ↓
SOLUTION: Spec Discovery           SOLUTION: Ralph Loop
(iron out everything first)        (agent builds while you sleep)
```

The pipeline this template creates:

```
💡 Raw Idea
    │
    ▼
/spec-discovery          ← Claude Code interviews you across 10 categories.
    │                       Produces docs/SPEC.md automatically.
    │                       Asks questions you wouldn't think to ask yourself:
    │                       auth approach, data model, third-party API access,
    │                       edge cases, deployment target, env vars needed.
    ▼
docs/SPEC.md             ← Your source of truth. Review and edit it.
    │                       Every vague idea becomes a concrete decision here.
    │                       Every external dependency gets named and verified.
    ▼
/spec-to-prd             ← Claude Code reads the spec and generates prd.json:
    │                       properly-sized stories, acceptance criteria,
    │                       technical notes, dependency ordering.
    ▼
prd.json                 ← The executable task list. Each story is sized to
    │                       fit in a single AI context window.
    ▼
/env-check               ← Verifies every API key, service, and env var is
    │                       in place before the loop runs. Catches blockers
    │                       before they abort a build at 2am.
    ▼
./scripts/ralph/ralph.sh ← The loop. Spawns Claude Code repeatedly.
    │                       Each iteration: fresh context window → pick next
    │                       story → implement → run tests → commit → repeat.
    ▼
git log                  ← You wake up to completed features.
```

---

## How the Ralph Loop Works

The loop runner (`scripts/ralph/ralph.sh`) is a bash script that calls Claude Code in a tight cycle:

```bash
for i in 1..N:
    claude -p "$(cat scripts/ralph/CLAUDE.md)"
    if all stories pass → exit
    if completion signal found → exit
```

**The critical design principle:** each iteration spawns a completely new Claude Code instance with a clean context window. This is intentional. Long-running single sessions accumulate context, which leads to drift and hallucination. Fresh context per iteration keeps output quality high across 20+ iterations.

**Memory across iterations is explicit, not implicit.** The agent doesn't "remember" previous iterations — it reads them:

| Memory Source | What It Contains |
|---------------|-----------------|
| `prd.json` | Which stories are done (`"passes": true`) and which aren't |
| `progress.txt` | Append-only log: gotchas, patterns discovered, what was built |
| `git history` | The actual code, commit by commit |

**The per-iteration agent instructions** (`scripts/ralph/CLAUDE.md`) tell each fresh instance exactly what to do: read the context files, find the first incomplete story, implement it, run the test command, update `prd.json`, append to `progress.txt`, commit, and output a completion signal.

No story gets marked `"passes": true` unless the test command actually passes. This is the loop's integrity guarantee.

---

## How Spec Discovery Prevents the Most Common Failure Modes

The `/spec-discovery` command runs Claude Code as an interviewer, working through 10 structured categories before writing a single line to `docs/SPEC.md`:

| Category | What It Catches |
|----------|----------------|
| Core Problem | Validates that the idea solves a real, specific problem — not a vague one |
| Users & Roles | Surfaces multi-role requirements and permission models you might assume but not state |
| Feature Deep-Dives | Forces edge cases, empty states, and error states to be specified *before* building |
| Auth & Authorization | Gets a concrete decision on auth provider, methods, and role permissions |
| Data Model | Sketches entities and relationships before any code touches a database |
| External Integrations | Names every third-party service and flags whether API access is confirmed |
| Tech Stack | Locks the framework, ORM, deployment target, and package manager |
| Environment Variables | Enumerates every required env var so nothing is missing at build time |
| Non-Functional Requirements | Captures performance, mobile, accessibility, and SEO needs |
| Risks & Unknowns | Surfaces the things most likely to derail the project |

The output is `docs/SPEC.md` — a complete, structured document written directly to disk by Claude Code. No copy-pasting. You review it, edit anything that looks off, and when it feels right, you run `/spec-to-prd`.

---

## How Story Sizing Makes the Loop Reliable

The most common failure mode with agentic loops is over-scoped stories. An agent given "build the authentication system" will either attempt too much in one shot (and fail partway through), or make decisions you didn't sanction.

The `/spec-to-prd` command enforces a strict sizing rule: **one story = one deployable unit of work that fits in a single context window.** In practice, that means:

**✅ Right-sized:**
- One UI component
- One API endpoint or server action
- One database migration
- One page with data fetching
- One auth flow step (sign-in page, sign-up page, middleware, user sync — each a separate story)

**❌ Too large — the command breaks these down automatically:**
- "Set up authentication"
- "Build the dashboard"
- "Integrate Stripe"
- "Create the user profile"

Stories are also ordered by dependency — scaffolding before database before auth before features before polish. The agent can't get stuck waiting on something that hasn't been built yet.

---

## File Structure

```
your-project/
├── CLAUDE.md                        Auto-loaded by Claude Code on every session.
│                                    Tracks current phase, tech stack, open questions,
│                                    codebase conventions, and recent decisions.
│
├── .claude/
│   ├── settings.json                Permission allowlist/denylist for sandboxed runs.
│   │                                Prevents destructive commands during autonomous loops.
│   └── commands/
│       ├── spec-discovery.md        /spec-discovery — runs the discovery interview,
│       │                            writes docs/SPEC.md, updates CLAUDE.md.
│       ├── spec-to-prd.md           /spec-to-prd — reads docs/SPEC.md, writes prd.json
│       │                            with ordered, properly-sized stories.
│       └── env-check.md             /env-check — audits env vars against spec requirements,
│                                    runs preflight checks, reports blockers.
│
├── scripts/
│   └── ralph/
│       ├── ralph.sh                 The loop runner. Spawns Claude Code N times.
│       │                            Fresh context per iteration. Checks for completion
│       │                            signal and story status between runs.
│       └── CLAUDE.md                Per-iteration agent instructions. Read by every
│                                    fresh Claude Code instance. Tells it: read context,
│                                    pick story, implement, test, commit, signal done.
│
├── docs/
│   └── SPEC.md                      Product specification. Generated by /spec-discovery,
│                                    edited by you, read by /spec-to-prd.
│
├── prd.json                         Executable task list. Generated by /spec-to-prd,
│                                    updated by the Ralph loop (passes: true per story).
│
├── progress.txt                     Append-only agent learning log. Each Ralph iteration
│                                    appends what it built, what files it changed,
│                                    and any gotchas discovered.
│
├── .env.example                     All required environment variables with descriptions.
│                                    Committed to git. No real values.
│
├── .env.local                       Your actual secrets. Never committed.
│                                    Created from .env.example by setup.sh.
│
├── .gitignore                       Ignores .env.local, node_modules, .next, etc.
│
└── setup.sh                         One-time setup script. Creates directories,
                                     makes ralph.sh executable, initializes git,
                                     creates .env.local from template.
```

---

## Quick Start

### 1. Copy the template and run setup

```bash
cp -r project-template/ my-new-app/
cd my-new-app/
./setup.sh my-new-app
```

### 2. Open in Claude Code

```bash
claude .
```

Claude Code automatically reads `CLAUDE.md` and knows the project context, current phase, and available commands.

### 3. Run the discovery interview

```
/spec-discovery
```

Claude will interview you across 10 categories. Answer as much as you know — "I don't know yet" is a valid answer. It writes `docs/SPEC.md` directly to disk when complete and updates the phase tracker in `CLAUDE.md`.

### 4. Review and edit the spec

Open `docs/SPEC.md`. Read every section. Look for anything vague, wrong, or missing. Edit freely — this is your source of truth and the spec is yours to own.

### 5. Convert the spec to a task list

```
/spec-to-prd
```

Claude reads `docs/SPEC.md` and writes `prd.json` with properly-sized, ordered stories. Review the story list and check that sizing feels right.

### 6. Verify your environment

```
/env-check
```

Claude audits your `.env.local` against every service and variable the spec requires. Resolves blockers before the loop starts.

### 7. Build

```bash
./scripts/ralph/ralph.sh 20
```

The loop runs up to 20 iterations. Each iteration picks the next incomplete story, implements it, runs your test command, commits to git, and marks the story complete. Check `git log` and `prd.json` when it finishes.

If stories remain after the run, re-run:

```bash
./scripts/ralph/ralph.sh 20
```

---

## Tuning the Loop

### Adjust the test command

Edit `prd.json` → `stack.testCommand`. The default is:
```
npm run typecheck && npm test
```

Match this to your actual stack. The loop will not mark a story complete unless this command passes.

### Adjust iteration count

```bash
./scripts/ralph/ralph.sh 10    # conservative
./scripts/ralph/ralph.sh 25    # aggressive overnight run
```

Start with 10 for a new project to verify the loop is working before committing to a long run.

### Use Amp instead of Claude Code

```bash
./scripts/ralph/ralph.sh 20 --tool amp
```

### Add to the PRD mid-project

You can add new stories to `prd.json` at any time with `"passes": false`. The loop will pick them up on the next run. Run `/spec-to-prd` again if you update `docs/SPEC.md` first — it can append to an existing PRD rather than regenerate from scratch.

---

## The Role Shift

This workflow changes what you do as a developer. You're no longer the one writing the code — you're the one owning the spec, reviewing the output, and steering the direction.

In practice, that means:

- **Before the loop:** you invest time in the spec and the PRD. This is the work. A good spec is the biggest lever on output quality.
- **During the loop:** you're not watching it. You're doing other things, or sleeping. The loop runs autonomously.
- **After the loop:** you review commits like PRs from a developer. You check that features work. You update the spec with anything that changed during build. You re-run for the next batch.

Ryan Carson described this as "managing agents the way you'd manage people" — specify, then check, then give feedback. The spec is the specification. The PRD is the sprint. The git log is the standup. The loop is the developer.

---

## Credits

The Ralph Wiggum agentic loop technique was developed and popularized by **Ryan Carson**. Original post: [x.com/ryancarson/status/2023452909883609111](https://x.com/ryancarson/status/2023452909883609111). Implementation reference: [github.com/snarktank/ralph](https://github.com/snarktank/ralph).

The spec-driven development workflow and Claude Code integration in this template were designed to solve the upstream problem the Ralph technique assumes is already solved: having a well-defined, properly-scoped task list before the loop begins.
