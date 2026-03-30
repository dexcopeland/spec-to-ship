#!/bin/bash

# ════════════════════════════════════════════════════════════════
#  Ralph — Autonomous AI Coding Loop
#  Usage: ./scripts/ralph/ralph.sh [iterations] [--tool claude|amp]
#  Default: 20 iterations with Claude Code
# ════════════════════════════════════════════════════════════════

ITERATIONS=${1:-20}
TOOL="claude"
PROMPT_FILE="scripts/ralph/CLAUDE.md"
COMPLETION_SIGNAL="<promise>COMPLETE</promise>"
LOG_FILE="progress.txt"

# Parse flags
for arg in "$@"; do
  case $arg in
    --tool) shift; TOOL=$1 ;;
  esac
done

# ── Preflight checks ────────────────────────────────────────────
if [ ! -f "$PROMPT_FILE" ]; then
  echo "❌ Missing $PROMPT_FILE — cannot start."
  exit 1
fi

if [ ! -f "prd.json" ]; then
  echo "❌ Missing prd.json — run /spec-to-prd in Claude Code first."
  exit 1
fi

# Check if there are any incomplete stories
INCOMPLETE=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
if [ "$INCOMPLETE" = "0" ]; then
  echo "✅ All stories already passing. Nothing to do."
  exit 0
fi

# ── Start ────────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "" >> "$LOG_FILE"
echo "════════════════════════════════════" >> "$LOG_FILE"
echo "Ralph run started: $TIMESTAMP" >> "$LOG_FILE"
echo "Tool: $TOOL | Max iterations: $ITERATIONS" >> "$LOG_FILE"
echo "════════════════════════════════════" >> "$LOG_FILE"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  🤖 Ralph — Autonomous Build Loop   ║"
echo "╠══════════════════════════════════════╣"
echo "║  Tool:       $TOOL"
echo "║  Max loops:  $ITERATIONS"
echo "║  Remaining:  $INCOMPLETE stories"
echo "║  Log:        $LOG_FILE"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Loop ─────────────────────────────────────────────────────────
for i in $(seq 1 $ITERATIONS); do

  # Check remaining stories before each iteration
  REMAINING=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
  NEXT_STORY=$(cat prd.json | jq -r '[.userStories[] | select(.passes == false)][0].title' 2>/dev/null)

  if [ "$REMAINING" = "0" ]; then
    echo ""
    echo "✅ All stories complete! Ralph is done."
    echo "Ralph completed all stories at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    break
  fi

  echo "┌─────────────────────────────────────────"
  echo "│ Iteration $i / $ITERATIONS  •  $(date '+%H:%M:%S')"
  echo "│ Remaining: $REMAINING stories"
  echo "│ Next: $NEXT_STORY"
  echo "└─────────────────────────────────────────"
  echo ""

  # Run the agent — fresh context each iteration
  if [ "$TOOL" = "amp" ]; then
    OUTPUT=$(amp -p "$(cat $PROMPT_FILE)" 2>&1)
  else
    OUTPUT=$(claude -p "$(cat $PROMPT_FILE)" 2>&1)
  fi

  # Log output
  echo "" >> "$LOG_FILE"
  echo "── Iteration $i ($(date '+%H:%M:%S')) ──" >> "$LOG_FILE"
  echo "$OUTPUT" >> "$LOG_FILE"

  # Print to console
  echo "$OUTPUT"

  # Check for explicit completion signal
  if echo "$OUTPUT" | grep -q "$COMPLETION_SIGNAL"; then
    echo ""
    echo "✅ Completion signal received. Ralph is done."
    break
  fi

  # Brief pause between iterations (avoids rate limit spikes)
  if [ $i -lt $ITERATIONS ]; then
    sleep 2
  fi

done

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Ralph Run Complete                  ║"
echo "╚══════════════════════════════════════╝"

FINAL_DONE=$(cat prd.json | jq '[.userStories[] | select(.passes == true)] | length' 2>/dev/null)
FINAL_REMAINING=$(cat prd.json | jq '[.userStories[] | select(.passes == false)] | length' 2>/dev/null)
TOTAL=$(cat prd.json | jq '.userStories | length' 2>/dev/null)

echo ""
echo "  Stories completed: $FINAL_DONE / $TOTAL"
echo "  Stories remaining: $FINAL_REMAINING"
echo ""
echo "  Review: git log --oneline -$ITERATIONS"
echo "  Status: cat prd.json | jq '.userStories[] | {id, title, passes}'"
echo ""

if [ "$FINAL_REMAINING" != "0" ]; then
  echo "  💡 Stories remain — re-run: ./scripts/ralph/ralph.sh $ITERATIONS"
fi
