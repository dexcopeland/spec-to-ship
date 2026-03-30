#!/bin/bash

# ════════════════════════════════════════════════════════════════
#  Ralph — Autonomous AI Coding Loop (Linear-integrated)
#  Usage: ./scripts/ralph/ralph.sh [iterations] [--tool claude|amp]
#  Default: 20 iterations with Claude Code
#
#  Linear error handling:
#    - Each iteration has a timeout guard (default: 10 min)
#    - Failed Linear updates are queued in linear-retry.json
#    - A post-run flush attempts to clear the queue after the loop
#    - Run /linear-retry in Claude Code to manually flush at any time
# ════════════════════════════════════════════════════════════════

ITERATIONS=${1:-20}
TOOL="claude"
PROMPT_FILE="scripts/ralph/CLAUDE.md"
COMPLETION_SIGNAL="<promise>COMPLETE</promise>"
LOG_FILE="progress.txt"
RETRY_FILE="linear-retry.json"
ITERATION_TIMEOUT=600   # seconds per iteration (10 min); raise if your stories are large

# Parse flags
for arg in "$@"; do
  case $arg in
    --tool) shift; TOOL=$1 ;;
    --timeout) shift; ITERATION_TIMEOUT=$1 ;;
  esac
done

# ── Helper: count pending Linear retries ────────────────────────
count_retries() {
  if [ -f "$RETRY_FILE" ]; then
    jq '[.pendingUpdates // [] | length] | .[0]' "$RETRY_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# ── Helper: print retry queue status ────────────────────────────
show_retry_status() {
  local count
  count=$(count_retries)
  if [ "$count" -gt "0" ]; then
    echo "  ⚠️  Linear retry queue: $count pending update(s)"
    jq -r '.pendingUpdates[] | "     → \(.linearIssueId) [\(.targetState)] \(.storyTitle) (attempt \(.attempts))"' "$RETRY_FILE" 2>/dev/null
  else
    echo "  ✅ Linear retry queue: empty"
  fi
}

# ── Preflight checks ────────────────────────────────────────────
if [ ! -f "$PROMPT_FILE" ]; then
  echo "❌ Missing $PROMPT_FILE — cannot start."
  exit 1
fi

if [ ! -f "prd.json" ]; then
  echo "❌ Missing prd.json — run /spec-to-prd in Claude Code first."
  exit 1
fi

# Ensure linear-retry.json exists
if [ ! -f "$RETRY_FILE" ]; then
  echo '{"lastUpdated": null, "pendingUpdates": []}' > "$RETRY_FILE"
fi

INCOMPLETE=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
if [ "$INCOMPLETE" = "0" ]; then
  echo "✅ All stories already passing. Nothing to do."
  RETRIES=$(count_retries)
  if [ "$RETRIES" -gt "0" ]; then
    echo ""
    echo "  ⚠️  But there are $RETRIES pending Linear updates."
    echo "  Run /linear-retry in Claude Code to flush them."
  fi
  exit 0
fi

LINEAR_PROJECT=$(cat prd.json | jq -r '.linearProjectId // "not set"' 2>/dev/null)
RETRIES_AT_START=$(count_retries)

# ── Start ────────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "" >> "$LOG_FILE"
echo "════════════════════════════════════" >> "$LOG_FILE"
echo "Ralph run started: $TIMESTAMP" >> "$LOG_FILE"
echo "Tool: $TOOL | Max iterations: $ITERATIONS | Timeout: ${ITERATION_TIMEOUT}s" >> "$LOG_FILE"
echo "Linear project: $LINEAR_PROJECT" >> "$LOG_FILE"
echo "Pending Linear retries at start: $RETRIES_AT_START" >> "$LOG_FILE"
echo "════════════════════════════════════" >> "$LOG_FILE"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  🤖 Ralph — Autonomous Build Loop       ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Tool:          $TOOL"
echo "║  Max loops:     $ITERATIONS"
echo "║  Story timeout: ${ITERATION_TIMEOUT}s per iteration"
echo "║  Remaining:     $INCOMPLETE stories"
echo "║  Linear:        $LINEAR_PROJECT"
printf "║  Retry queue:   "
if [ "$RETRIES_AT_START" -gt "0" ]; then
  echo "$RETRIES_AT_START pending (will flush first)"
else
  echo "empty"
fi
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Loop ─────────────────────────────────────────────────────────
TIMED_OUT_COUNT=0
LINEAR_FAIL_COUNT=0

for i in $(seq 1 $ITERATIONS); do

  REMAINING=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
  NEXT_STORY=$(cat prd.json | jq -r '[.userStories[] | select(.passes == false)][0].title' 2>/dev/null)
  NEXT_LINEAR=$(cat prd.json | jq -r '[.userStories[] | select(.passes == false)][0].linearIssueId // "no Linear ID"' 2>/dev/null)
  CURRENT_RETRIES=$(count_retries)

  if [ "$REMAINING" = "0" ]; then
    echo ""
    echo "✅ All stories complete!"
    echo "Ralph completed all stories at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    break
  fi

  echo "┌─────────────────────────────────────────────────"
  echo "│ Iteration $i / $ITERATIONS  •  $(date '+%H:%M:%S')"
  echo "│ Remaining stories: $REMAINING"
  echo "│ Next: $NEXT_STORY"
  echo "│ Linear: $NEXT_LINEAR"
  if [ "$CURRENT_RETRIES" -gt "0" ]; then
    echo "│ ⚠️  Linear retry queue: $CURRENT_RETRIES item(s) — will flush first"
  fi
  echo "└─────────────────────────────────────────────────"
  echo ""

  # ── Run the agent with a timeout guard ──────────────────────────
  ITER_START=$(date +%s)

  if [ "$TOOL" = "amp" ]; then
    timeout $ITERATION_TIMEOUT amp -p "$(cat $PROMPT_FILE)" 2>&1
    EXIT_CODE=$?
  else
    timeout $ITERATION_TIMEOUT claude -p "$(cat $PROMPT_FILE)" 2>&1
    EXIT_CODE=$?
  fi

  OUTPUT=$( [ "$TOOL" = "amp" ] && timeout $ITERATION_TIMEOUT amp -p "$(cat $PROMPT_FILE)" 2>&1 || timeout $ITERATION_TIMEOUT claude -p "$(cat $PROMPT_FILE)" 2>&1 )
  EXIT_CODE=$?
  ITER_DURATION=$(( $(date +%s) - ITER_START ))

  # Log output
  echo "" >> "$LOG_FILE"
  echo "── Iteration $i ($(date '+%H:%M:%S'), ${ITER_DURATION}s) ──" >> "$LOG_FILE"

  # ── Handle timeout ───────────────────────────────────────────────
  if [ $EXIT_CODE -eq 124 ]; then
    TIMED_OUT_COUNT=$((TIMED_OUT_COUNT + 1))
    TIMEOUT_MSG="⚠️  Iteration $i timed out after ${ITERATION_TIMEOUT}s. Story may be incomplete."
    echo "$TIMEOUT_MSG"
    echo "$TIMEOUT_MSG" >> "$LOG_FILE"
    echo "  → If this keeps happening, increase timeout: ./scripts/ralph/ralph.sh $ITERATIONS --timeout 900"
    echo "  → Or break the current story into smaller pieces in prd.json"
    echo ""

    # Check if the story was actually marked complete despite the timeout
    NEW_REMAINING=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
    if [ "$NEW_REMAINING" = "$REMAINING" ]; then
      echo "  → Story was not marked complete. Continuing to next iteration."
    else
      echo "  → Story appears to have completed before timeout. Continuing."
    fi

    sleep 3
    continue
  fi

  echo "$OUTPUT" >> "$LOG_FILE"
  echo "$OUTPUT"

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "$COMPLETION_SIGNAL"; then
    echo ""
    echo "✅ Completion signal received."
    break
  fi

  # Track if Linear calls seem to be failing (queue growing)
  NEW_RETRIES=$(count_retries)
  if [ "$NEW_RETRIES" -gt "$CURRENT_RETRIES" ]; then
    ADDED=$((NEW_RETRIES - CURRENT_RETRIES))
    LINEAR_FAIL_COUNT=$((LINEAR_FAIL_COUNT + ADDED))
    echo "  ⚠️  $ADDED Linear update(s) queued (retry queue now: $NEW_RETRIES)"
  fi

  # Brief pause between iterations
  if [ $i -lt $ITERATIONS ]; then
    sleep 2
  fi

done

# ── Post-run: attempt to flush Linear retry queue ─────────────────
FINAL_RETRIES=$(count_retries)

if [ "$FINAL_RETRIES" -gt "0" ]; then
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║  🔄 Flushing Linear Retry Queue...       ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "  $FINAL_RETRIES pending update(s) to sync with Linear."
  echo "  Attempting flush now..."
  echo ""

  FLUSH_PROMPT="Read linear-retry.json. For each item in pendingUpdates, attempt the Linear update as described in scripts/ralph/CLAUDE.md Step 2. After processing all items, write the updated linear-retry.json to disk. Print a summary of what succeeded and what remains. Output <promise>COMPLETE</promise> when done."

  timeout 120 claude -p "$FLUSH_PROMPT" 2>&1
  FLUSH_EXIT=$?

  if [ $FLUSH_EXIT -eq 124 ]; then
    echo "  ⚠️  Flush timed out. Run /linear-retry in Claude Code to try again."
  fi

  AFTER_FLUSH=$(count_retries)
  if [ "$AFTER_FLUSH" = "0" ]; then
    echo "  ✅ All Linear updates synced."
  else
    echo "  ⚠️  $AFTER_FLUSH update(s) still pending."
    echo "  Run /linear-retry in Claude Code when Linear is available."
  fi
fi

# ── Final Summary ─────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Ralph Run Complete                      ║"
echo "╚══════════════════════════════════════════╝"

FINAL_DONE=$(cat prd.json | jq '[.userStories[] | select(.passes == true)] | length' 2>/dev/null)
FINAL_REMAINING=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
TOTAL=$(cat prd.json | jq '.userStories | length' 2>/dev/null)
FINAL_RETRIES=$(count_retries)

echo ""
echo "  Stories completed: $FINAL_DONE / $TOTAL"
echo "  Stories remaining: $FINAL_REMAINING"
if [ "$TIMED_OUT_COUNT" -gt "0" ]; then
  echo "  Timed-out iterations: $TIMED_OUT_COUNT"
fi
echo ""
echo "  Linear status:"
show_retry_status
echo ""
echo "  Review commits:    git log --oneline -20"
if [ "$FINAL_RETRIES" -gt "0" ]; then
  echo "  Sync Linear:       /linear-retry  (in Claude Code)"
fi
echo ""

if [ "$FINAL_REMAINING" != "0" ]; then
  echo "  💡 Stories remain — re-run: ./scripts/ralph/ralph.sh $ITERATIONS"
fi
