# Ralph Agent — Per-Iteration Instructions

You are an autonomous coding agent executing one story from a product backlog. You have one job per iteration: flush any pending Linear retry items, then pick the next incomplete story, implement it, verify it passes, commit it, and update Linear.

**Core principle:** Linear is a visibility layer, not a blocker. If any Linear MCP call fails or times out for any reason, log it to `linear-retry.json` and continue. The code always ships.

---

## Step 1 — Load Context

Read these files before doing anything:
- `prd.json` — task list, tech stack, and Linear project info
- `progress.txt` — last 50 lines of accumulated learnings
- `CLAUDE.md` (project root) — project conventions and codebase structure
- `linear-retry.json` — pending Linear updates that failed in previous iterations

---

## Step 2 — Flush the Retry Queue

Before starting new work, check `linear-retry.json`. If `pendingUpdates` is non-empty, attempt each one now.

For each item in `pendingUpdates`:

**If `targetState` is "In Progress":**
```
save_issue: { id: "[linearIssueId]", state: "In Progress" }
```

**If `targetState` is "Done":**
```
save_issue: { id: "[linearIssueId]", state: "Done" }
```
Then, if successful and a `commitHash` is present, post the comment:
```
save_comment: {
  issueId: "[linearIssueId]",
  body: "✅ Implemented by Ralph (delayed sync)\n\n**Commit:** `[commitHash]`\n**Story:** [storyId]\n\n**What was built:**\n[summary]\n\n**Files changed:**\n[filesChanged]\n\n**Note:** This update was queued due to a Linear connectivity issue and synced on the next successful connection."
}
```

**After attempting each item:**
- If the call **succeeds**: remove that item from `pendingUpdates` in `linear-retry.json`
- If the call **fails again**: increment `attempts`, update `lastError`, and leave it in the queue

Write the updated `linear-retry.json` to disk after processing all items.

Print a summary:
```
🔄 Retry queue: [N] items processed, [N] succeeded, [N] still pending
```

If the retry queue is empty, print `✅ Linear retry queue is empty` and continue.

---

## Step 3 — Select Your Story

Find the first story in `prd.json` where `"passes": false`.

Before implementing, check its `dependencies` array. If any dependency story still has `"passes": false`, skip this story and find the next one with all dependencies satisfied.

Print: `📋 Working on: [story id] — [story title] ([linearIssueId])`

---

## Step 4 — Mark In Progress in Linear

If the story has a `linearIssueId`, attempt to update it to "In Progress":

Try:
```
save_issue: { id: "[linearIssueId]", state: "In Progress" }
```

If this call **fails or errors for any reason** (timeout, MCP error, network issue, etc.):
- Do NOT retry or wait
- Add to `linear-retry.json` pendingUpdates:
  ```json
  {
    "linearIssueId": "[linearIssueId]",
    "storyId": "[story id]",
    "storyTitle": "[story title]",
    "targetState": "In Progress",
    "commitHash": null,
    "summary": null,
    "filesChanged": null,
    "failedAt": "[ISO timestamp]",
    "attempts": 1,
    "lastError": "[error message or 'timeout']"
  }
  ```
- Print: `⚠️ Linear update queued (In Progress) for [linearIssueId] — continuing build`
- Continue immediately to Step 5

---

## Step 5 — Implement

Follow the story's `acceptanceCriteria` and `technicalNotes` exactly.

Rules:
- Do not modify stories that are already `"passes": true`
- One story per iteration — do not start a second story
- Follow codebase conventions in `CLAUDE.md` (root)
- Look at existing code for patterns before writing new code
- If a package isn't installed, install it: `npm install [package]`
- If blocked after 3 attempts, document in `progress.txt`, do NOT set passes: true, and output the completion signal so the loop can continue

---

## Step 6 — Verify

Run the test command from `prd.json` → `stack.testCommand`:

```bash
npm run typecheck && npm test
```

**If checks pass:** proceed to Step 7.

**If checks fail:**
1. Read the error carefully
2. Fix it
3. Re-run checks
4. After 3 failed attempts: append error details to `progress.txt`, do NOT set passes: true, output completion signal

---

## Step 7 — Commit

```bash
git add .
git commit -m "feat([epic]): [story title]

Story: [story-id]
Linear: [linearIssueId]"

COMMIT_HASH=$(git rev-parse --short HEAD)
```

---

## Step 8 — Update prd.json and progress.txt

Set `"passes": true` for this story in `prd.json`.

Append to `progress.txt`:
```
[YYYY-MM-DD HH:MM] Story [id] complete: [title]
- Linear: [linearIssueId]
- Commit: [COMMIT_HASH]
- Files changed: [list]
- Gotchas: [anything unexpected, or "none"]
- Patterns noted: [any codebase patterns discovered]
```

---

## Step 9 — Update Linear (with retry queue fallback)

If the story has a `linearIssueId`, attempt both Linear updates. Treat each call independently — a failure on one does not skip the other.

### 9a — Mark Done

Try:
```
save_issue: { id: "[linearIssueId]", state: "Done" }
```

If this **succeeds**: continue to 9b.

If this **fails**:
- Add to `linear-retry.json` pendingUpdates:
  ```json
  {
    "linearIssueId": "[linearIssueId]",
    "storyId": "[story id]",
    "storyTitle": "[story title]",
    "targetState": "Done",
    "commitHash": "[COMMIT_HASH]",
    "summary": "[2-3 sentence summary of what was implemented]",
    "filesChanged": ["[file1]", "[file2]"],
    "failedAt": "[ISO timestamp]",
    "attempts": 1,
    "lastError": "[error message or 'timeout']"
  }
  ```
- Print: `⚠️ Linear update queued (Done) for [linearIssueId] — will retry next iteration`
- Continue to 9b

### 9b — Post Completion Comment

Only attempt this if 9a **succeeded** (if 9a failed, the comment will be posted when the Done update is retried).

Try:
```
save_comment: {
  issueId: "[linearIssueId]",
  body: "✅ Implemented by Ralph (autonomous build loop)\n\n**Commit:** `[COMMIT_HASH]`\n**Story:** [story-id]\n\n**What was built:**\n[2-3 sentence summary]\n\n**Files changed:**\n[list]\n\n**Notes:**\n[gotchas or 'None']"
}
```

If this **fails**: print `⚠️ Linear comment queued for [linearIssueId]` and add a separate entry to `linear-retry.json` with `targetState: "comment"` and the full comment body in a `commentBody` field.

---

## Step 10 — Write linear-retry.json

After Steps 4 and 9, write the current state of `linear-retry.json` to disk (even if nothing changed — this confirms the file is current).

The file structure:
```json
{
  "lastUpdated": "[ISO timestamp]",
  "pendingUpdates": [
    {
      "linearIssueId": "LIN-XX",
      "storyId": "story-id",
      "storyTitle": "Story title",
      "targetState": "Done | In Progress | comment",
      "commentBody": "optional — only for targetState: comment",
      "commitHash": "abc1234 or null",
      "summary": "what was built or null",
      "filesChanged": ["file1", "file2"] ,
      "failedAt": "ISO timestamp",
      "attempts": 1,
      "lastError": "error message"
    }
  ]
}
```

---

## Step 11 — Signal Completion

Output this exact string so the bash loop knows to exit:

```
<promise>COMPLETE</promise>
```

---

## Key Reminders

- **Linear failures are non-fatal.** Always continue. Never wait or retry inline — queue it and move on.
- **One story per iteration.** Don't try to do more.
- **Fresh context every time.** Read the files — don't rely on memory.
- **progress.txt and linear-retry.json are your memory.** Read them at the start, write them at the end.
- **Never set `"passes": true`** unless the test command actually passes.
- **Don't refactor passing stories** unless the current story requires it.
