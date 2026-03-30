# Spec-Driven Agentic Dev Template — Linear Edition

A Claude Code project template that takes you from a raw idea to shipped code — autonomously — by combining spec-driven development with an agentic coding loop that keeps your Linear workspace in sync at every step.

This is the Linear-integrated version of the base template. Every story created in your `prd.json` becomes a Linear issue. Every story the Ralph loop completes gets marked Done in Linear with a comment containing the commit hash.

---

## Origin: The Ralph Wiggum Technique

This template is built around a technique popularized by **Ryan Carson** (Builder-in-Residence at Amp) in a widely-shared post on X. The core observation was deceptively simple:

> Give an AI agent a structured task list. Let it pick one item, implement it, run tests, commit the result, and repeat — autonomously — until the list is empty.

Carson named this the **Ralph Wiggum** technique, after the Simpsons character — embodying persistent, cheerful iteration. The result: you wake up to a git log full of completed features.

The technique works because it enforces discipline: small, well-defined tasks, automated quality checks on every iteration, and a loop that can't drift because each iteration starts with a completely fresh context window.

But there was a catch that this template addresses: **the loop is only as good as the task list going into it.** Most developers — jumping straight from an idea to a backlog — produce task lists that are vague, over-scoped, missing dependencies, or built on unverified assumptions. And the original technique had no project management layer — no way to see what was built, what's in progress, or what's left without reading raw JSON.

This template solves both problems.

---

## What This Template Adds Over the Base Version

The base template gives you spec-driven development + the Ralph loop. This version adds **Linear as the live project management layer** that stays synchronized with every step of the workflow:

| Event | Base Template | Linear Edition |
|-------|--------------|----------------|
| `/spec-discovery` completes | Writes `docs/SPEC.md` | + Creates Linear project + uploads spec as a document |
| `/spec-to-prd` completes | Writes `prd.json` | + Creates Linear issues for every story, with epic labels, dependency links, and milestone |
| Ralph starts a story | Updates `prd.json` | + Marks Linear issue "In Progress" |
| Ralph completes a story | Sets `passes: true`, commits | + Marks Linear issue "Done" + posts comment with commit hash |
| Out of sync | Manual fix | Run `/linear-sync` to reconcile automatically |

The result: you can open Linear at any point and see exactly where the build stands — what's been shipped, what's in flight, and what's queued.

---

## The Full Pipeline

```
💡 Raw Idea
    │
    ▼
/spec-discovery
    │   Claude Code interviews you across 10 categories.
    │   Writes docs/SPEC.md directly to disk.
    │   Then automatically:
    │     → Creates a Linear project
    │     → Uploads the spec as a Linear document
    │     → Creates an MVP milestone
    │
    ▼
docs/SPEC.md + Linear Project
    │
    │   You review and edit the spec.
    │   Every vague idea becomes a concrete decision.
    │   Every external dependency gets named and verified.
    │
    ▼
/spec-to-prd
    │   Reads docs/SPEC.md.
    │   Generates prd.json with sized, ordered, dependency-linked stories.
    │   Then automatically:
    │     → Creates epic labels in Linear (one per unique epic, color-coded)
    │     → Creates a Linear issue for every story (title, acceptance criteria,
    │        technical notes, priority, epic label, milestone)
    │     → Wires blockedBy relationships between dependent issues
    │     → Writes linearIssueId back into each story in prd.json
    │
    ▼
prd.json + Linear Board (all issues in "Todo")
    │
    ▼
/env-check
    │   Verifies API keys, services, and env vars.
    │   Confirms Linear project and issues are set up.
    │   Reports any blockers before the loop runs.
    │
    ▼
./scripts/ralph/ralph.sh 20
    │   Spawns Claude Code up to 20 times.
    │   Each iteration, fresh context:
    │     1. Read prd.json + progress.txt + CLAUDE.md
    │     2. Find next incomplete story
    │     3. Mark Linear issue → "In Progress"
    │     4. Implement
    │     5. Run test command (npm run typecheck && npm test)
    │     6. Commit to git
    │     7. Set passes: true in prd.json
    │     8. Mark Linear issue → "Done"
    │     9. Post comment to Linear issue with commit hash + summary
    │    10. Append to progress.txt
    │    11. Output completion signal
    │
    ▼
git log + Linear Board (stories moving to "Done" as they complete)
    │
    ▼
/linear-sync  (run any time to reconcile if anything drifted)
```

---

## How the Loop Keeps Linear in Sync

The per-iteration agent (`scripts/ralph/CLAUDE.md`) has two Linear-aware steps that don't exist in the base template:

**Before implementing** — marks the issue In Progress:
```
save_issue: { id: "LIN-42", state: "In Progress" }
```

**After a successful commit** — marks it Done and leaves a paper trail:
```
save_issue: { id: "LIN-42", state: "Done" }

save_comment: {
  issueId: "LIN-42",
  body: "✅ Implemented by Ralph\n\nCommit: abc1234\n\nWhat was built: ..."
}
```

Linear failures are intentionally **non-fatal** — the code always ships regardless of MCP availability.

---

## Linear Error Handling & Retry Queue

MCP connections can time out or drop. The template is designed so a flaky Linear connection never blocks a build.

### How it works

When any Linear MCP call fails, the agent immediately:
1. Writes the failed update to `linear-retry.json` with the issue ID, target state, commit hash, and error details
2. Prints a warning and continues to the next step — no waiting, no retrying inline

`linear-retry.json` is a simple queue file committed alongside your code:

```json
{
  "pendingUpdates": [
    {
      "linearIssueId": "LIN-42",
      "storyId": "auth-001",
      "targetState": "Done",
      "commitHash": "abc1234",
      "summary": "Created sign-in page using Clerk",
      "failedAt": "2026-03-30T02:14:00Z",
      "attempts": 1,
      "lastError": "MCP timeout"
    }
  ]
}
```

### Automatic retry opportunities

The queue gets flushed at three points automatically:

1. **Start of every iteration** — before picking up new work, the agent attempts to process all queued items from previous iterations
2. **After the loop ends** — `ralph.sh` runs a dedicated flush pass with a 2-minute timeout
3. **On timeout** — if an iteration exceeds the time limit (default: 10 min), the script logs it, checks whether the story was actually completed, and continues

### Manual flush

If the queue still has items after a run, or Linear was down for an extended period:

```
/linear-retry
```

This command reads `linear-retry.json`, attempts each update, removes successful ones, and reports what's still pending. It also detects when Linear appears fully unavailable (3+ consecutive failures) and stops early rather than hammering the API.

### Timeout tuning

The default per-iteration timeout is 10 minutes. If your stories are consistently large or your machine is slow:

```bash
./scripts/ralph/ralph.sh 20 --timeout 900   # 15 minutes per iteration
```

### What the retry comment looks like in Linear

When a queued "Done" update eventually syncs, the comment posted to the issue is clearly marked as a delayed sync:

> ✅ Implemented by Ralph (delayed sync from retry queue)
> **Commit:** `abc1234`
> **Note:** This update was queued due to a Linear connectivity issue and is being synced now.

---

## How Spec Discovery Populates Linear

When `/spec-discovery` finishes the interview and writes `docs/SPEC.md`, it immediately:

1. **Lists your Linear teams** and asks which one owns this project (auto-selects if you only have one)
2. **Creates a Linear project** with the app name and problem statement as the description
3. **Uploads the spec** as a Linear document attached to the project — so your entire spec lives inside Linear alongside the issues
4. **Creates an MVP milestone** — all issues created by `/spec-to-prd` are automatically filed under it

The project ID and team name are written into `CLAUDE.md` so every subsequent command knows where to find the Linear workspace without being told again.

---

## How Story Sizing Makes the Loop Reliable

Both this template and the base version enforce a strict rule: **one story = one deployable unit of work that fits in a single context window.**

This matters in the Linear context because it means every Linear issue represents a genuinely atomic piece of work — not a vague epic that could mean anything. Each issue has:

- A specific title ("Create sign-in page using Clerk's `<SignIn />` component")
- Checkbox-style acceptance criteria in the description
- Technical notes pointing to exact files and patterns
- An epic label for grouping
- A `blockedBy` relationship if it depends on another issue

When you look at the Linear board, you're seeing the actual granularity of the build — not project manager shorthand.

---

## File Structure

```
your-project/
├── CLAUDE.md                        Auto-loaded by Claude Code. Tracks phase,
│                                    stack, and Linear workspace info (team,
│                                    project ID, spec document ID).
│
├── .claude/
│   ├── settings.json                Permission allowlist for autonomous runs.
│   └── commands/
│       ├── spec-discovery.md        /spec-discovery — interview → SPEC.md
│       │                            + Linear project + spec document + milestone
│       ├── spec-to-prd.md           /spec-to-prd — SPEC.md → prd.json
│       │                            + Linear issues with labels + dependencies
│       ├── env-check.md             /env-check — env audit + Linear setup check
│       ├── linear-sync.md           /linear-sync — reconcile prd.json ↔ Linear
│       └── linear-retry.md          /linear-retry — flush the retry queue manually
│
├── scripts/
│   └── ralph/
│       ├── ralph.sh                 Loop runner. Shows Linear issue ID per
│       │                            iteration in console output.
│       └── CLAUDE.md                Per-iteration instructions. Includes Linear
│                                    "In Progress" and "Done" update steps.
│
├── docs/
│   └── SPEC.md                      Product spec. Also lives as a Linear document.
│
├── prd.json                         Task list. Each story has a linearIssueId
│                                    field populated by /spec-to-prd.
│
├── linear-retry.json                Queue of failed Linear MCP updates. Written
│                                    by the Ralph agent on any Linear failure.
│                                    Flushed at the start of each iteration and
│                                    after the loop. Run /linear-retry to flush
│                                    manually. Committed to git as project state.
│
├── progress.txt                     Append-only agent log. Includes Linear issue
│                                    ID and commit hash per completed story.
│
├── .env.example                     All required env vars. Committed to git.
├── .env.local                       Your actual secrets. Never committed.
├── .gitignore
└── setup.sh                         One-time setup script.
```

---

## Quick Start

### 1. Copy the template and run setup

```bash
cp -r project-template-linear/ my-new-app/
cd my-new-app/
./setup.sh my-new-app
```

### 2. Open in Claude Code

```bash
claude .
```

### 3. Run discovery — this sets up both your spec and your Linear project

```
/spec-discovery
```

Claude interviews you, writes `docs/SPEC.md`, then creates the Linear project, uploads the spec as a document, and creates the MVP milestone — all in one shot.

### 4. Review the spec

Read `docs/SPEC.md`. The same content is also in your Linear project as a document. Edit either one — just make sure they stay in sync before the next step.

### 5. Generate the task list and Linear issues

```
/spec-to-prd
```

This writes `prd.json` and simultaneously creates all your Linear issues with labels, acceptance criteria, and dependency relationships.

### 6. Verify your environment

```
/env-check
```

Checks env vars, services, and confirms the Linear setup is complete.

### 7. Build

```bash
./scripts/ralph/ralph.sh 20
```

Watch stories move from Todo → In Progress → Done in Linear as the loop runs.

### 8. Sync if anything drifted

```
/linear-sync
```

Compares `prd.json` against Linear and offers to reconcile — useful after manual edits in either system, or if a run was interrupted.

---

## The `/linear-sync` Command

This command is the safety net for the whole integration. It handles the reality that things go out of sync:

- You manually close an issue in Linear before Ralph gets to it
- A Ralph run was interrupted mid-iteration
- You edited `prd.json` directly
- You re-opened an issue in Linear to change something

When you run `/linear-sync`, it fetches the current state of every Linear issue in `prd.json`, compares it against the `passes` field, and gives you a clear report. Then it asks:

- **Trust prd.json** — update Linear to match
- **Trust Linear** — update prd.json to match
- **Fix manually** — go through each conflict one by one
- **Just report** — show the diff without making changes

---

## The Role Shift

This workflow changes what you do as a developer. You're the spec owner, the reviewer, and the steering force — not the one writing the code.

- **Before the loop:** invest time in the spec and PRD. This is where the real product thinking happens. Quality of spec = quality of output.
- **During the loop:** you're doing other things, or sleeping. Linear is your window into what's happening.
- **After the loop:** you review Linear issues the way you'd review PRs — reading the commit comments, checking what was built, deciding what comes next.

Ryan Carson described this as "managing agents the way you'd manage people" — specify, then check, then give feedback. With this template, Linear is where you do the checking.

---

## Credits

The Ralph Wiggum agentic loop technique was developed and popularized by **Ryan Carson**. Original post: [x.com/ryancarson/status/2023452909883609111](https://x.com/ryancarson/status/2023452909883609111). Implementation reference: [github.com/snarktank/ralph](https://github.com/snarktank/ralph).

The spec-driven development workflow, Linear integration, and Claude Code command architecture in this template were designed to address the upstream spec problem that the Ralph technique assumes is already solved — and to bring project visibility into the loop via Linear.
