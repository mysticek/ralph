#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--tool amp|claude] [--judge] [--judge-model MODEL] [--retries N] [max_iterations]

set -e

# Parse arguments
TOOL="amp"  # Default to amp for backwards compatibility
MAX_ITERATIONS=10
JUDGE_ENABLED=false
JUDGE_MODEL=""
MAX_RETRIES=2

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    --judge)
      JUDGE_ENABLED=true
      shift
      ;;
    --judge-model)
      JUDGE_MODEL="$2"
      JUDGE_ENABLED=true
      shift 2
      ;;
    --judge-model=*)
      JUDGE_MODEL="${1#*=}"
      JUDGE_ENABLED=true
      shift
      ;;
    --retries)
      MAX_RETRIES="$2"
      shift 2
      ;;
    --retries=*)
      MAX_RETRIES="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp' or 'claude'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
METRICS_FILE="$SCRIPT_DIR/ralph-metrics.csv"
JUDGE_PROMPT="$SCRIPT_DIR/judge-prompt.md"

# ─── Validate prd.json ───────────────────────────────────────────────
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: prd.json not found at $PRD_FILE"
  exit 1
fi

jq -e '.branchName and .userStories and (.userStories | length > 0)' "$PRD_FILE" > /dev/null 2>&1 || {
  echo "Error: Invalid prd.json structure. Required: branchName, userStories (non-empty array)."
  exit 1
}

# ─── Progress trimming ────────────────────────────────────────────────
trim_progress() {
  if [ ! -f "$PROGRESS_FILE" ]; then
    return
  fi

  local LINE_COUNT
  LINE_COUNT=$(wc -l < "$PROGRESS_FILE" | tr -d ' ')

  if [ "$LINE_COUNT" -gt 300 ]; then
    echo "Progress file has $LINE_COUNT lines, trimming..."

    # Archive full log
    local ARCHIVE_PROGRESS="$ARCHIVE_DIR/progress-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p "$ARCHIVE_DIR"
    cp "$PROGRESS_FILE" "$ARCHIVE_PROGRESS"
    echo "   Full log archived to: $ARCHIVE_PROGRESS"

    # Extract Codebase Patterns section
    local PATTERNS_SECTION
    PATTERNS_SECTION=$(awk '
      /^## Codebase Patterns/ { found=1 }
      found && /^## [0-9]/ { found=0 }
      found { print }
    ' "$PROGRESS_FILE")

    # Extract header (first 4 lines)
    local HEADER
    HEADER=$(head -4 "$PROGRESS_FILE")

    # Extract last 5 story entries (delimited by "---")
    local RECENT_ENTRIES
    RECENT_ENTRIES=$(awk '
      /^## [0-9]/ { block=""; capture=1 }
      capture { block = block $0 "\n" }
      /^---$/ && capture { blocks[++count] = block; capture=0; block="" }
      END {
        start = count - 4
        if (start < 1) start = 1
        for (i = start; i <= count; i++) printf "%s", blocks[i]
      }
    ' "$PROGRESS_FILE")

    # Rebuild trimmed progress file
    {
      echo "$HEADER"
      echo ""
      if [ -n "$PATTERNS_SECTION" ]; then
        echo "$PATTERNS_SECTION"
        echo ""
      fi
      echo "## [Older entries archived to $ARCHIVE_PROGRESS]"
      echo "---"
      echo ""
      echo "$RECENT_ENTRIES"
    } > "$PROGRESS_FILE"

    echo "   Trimmed to $(wc -l < "$PROGRESS_FILE" | tr -d ' ') lines (kept patterns + last 5 entries)"
  fi
}

# ─── Metrics ──────────────────────────────────────────────────────────
init_metrics() {
  if [ ! -f "$METRICS_FILE" ]; then
    echo "iteration,tool,story_id,stories_completed,duration_seconds,passing_before,passing_after,judge_verdict" > "$METRICS_FILE"
  fi
}

log_metric() {
  echo "$1,$TOOL,$2,$3,$4,$5,$6,$7" >> "$METRICS_FILE"
}

# ─── Judge ────────────────────────────────────────────────────────────
run_judge() {
  local STORY_ID="$1"

  if [[ "$JUDGE_ENABLED" != "true" ]]; then
    echo "PASS"
    return 0
  fi

  if [ ! -f "$JUDGE_PROMPT" ]; then
    echo "Warning: judge-prompt.md not found at $JUDGE_PROMPT, skipping judge" >&2
    echo "PASS"
    return 0
  fi

  echo "" >&2
  echo "  >> Running judge for $STORY_ID..." >&2

  # Get story details
  local STORY_INFO
  STORY_INFO=$(jq -r --arg id "$STORY_ID" '
    .userStories[] | select(.id == $id) |
    "Story: \(.id) - \(.title)\nDescription: \(.description)\n\nAcceptance Criteria:\n" +
    ([.acceptanceCriteria[] | "- " + .] | join("\n"))
  ' "$PRD_FILE" 2>/dev/null)

  # Get the last commit diff
  local DIFF
  DIFF=$(git diff HEAD~1..HEAD 2>/dev/null || echo "No diff available")

  # Build judge input
  local JUDGE_INPUT
  JUDGE_INPUT="$(cat "$JUDGE_PROMPT")

---

## Story Under Review

$STORY_INFO

## Git Diff

\`\`\`diff
$DIFF
\`\`\`

Review this diff against the acceptance criteria and output your verdict."

  # Run judge with appropriate tool
  local VERDICT_OUTPUT
  if [[ "$TOOL" == "amp" ]]; then
    VERDICT_OUTPUT=$(echo "$JUDGE_INPUT" | amp --dangerously-allow-all 2>/dev/null) || true
  else
    if [ -n "$JUDGE_MODEL" ]; then
      VERDICT_OUTPUT=$(echo "$JUDGE_INPUT" | claude --dangerously-skip-permissions --print --model "$JUDGE_MODEL" 2>/dev/null) || true
    else
      VERDICT_OUTPUT=$(echo "$JUDGE_INPUT" | claude --dangerously-skip-permissions --print 2>/dev/null) || true
    fi
  fi

  # Extract verdict
  if echo "$VERDICT_OUTPUT" | grep -q "VERDICT: PASS"; then
    echo "  >> Judge verdict: PASS" >&2
    echo "PASS"
    return 0
  elif echo "$VERDICT_OUTPUT" | grep -q "VERDICT: FAIL"; then
    # Extract reason for logging
    local REASON
    REASON=$(echo "$VERDICT_OUTPUT" | sed -n 's/^REASON: //p' | head -1)
    echo "  >> Judge verdict: FAIL" >&2
    echo "  >> Reason: $REASON" >&2
    echo "$VERDICT_OUTPUT" | grep -A20 "FAILED_CRITERIA:" >&2 || true
    # Return the full verdict output so caller can log it
    echo "FAIL:$REASON"
    return 1
  else
    echo "  >> Judge verdict: UNCLEAR (treating as PASS)" >&2
    echo "PASS"
    return 0
  fi
}

# ─── Archive previous run if branch changed ──────────────────────────
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Count passing stories
count_passing() {
  jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE" 2>/dev/null || echo 0
}

TOTAL_STORIES=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo 0)

init_metrics
trim_progress

echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo "Stories: $TOTAL_STORIES total, $(count_passing) already passing"
echo "Judge: $JUDGE_ENABLED (retries: $MAX_RETRIES)"
echo ""

# Track retry counts per story (using temp file for bash 3 compatibility)
RETRY_FILE=$(mktemp)
trap "rm -f '$RETRY_FILE'" EXIT

# Helper: get retry count for a story
get_retry_count() {
  local story_id="$1"
  local count=$(grep "^${story_id}=" "$RETRY_FILE" 2>/dev/null | tail -1 | cut -d= -f2)
  echo "${count:-0}"
}

# Helper: increment retry count for a story
inc_retry_count() {
  local story_id="$1"
  local current=$(get_retry_count "$story_id")
  local new_count=$((current + 1))
  # Remove old entry and add new one
  grep -v "^${story_id}=" "$RETRY_FILE" > "${RETRY_FILE}.tmp" 2>/dev/null || true
  mv "${RETRY_FILE}.tmp" "$RETRY_FILE"
  echo "${story_id}=${new_count}" >> "$RETRY_FILE"
}

for i in $(seq 1 $MAX_ITERATIONS); do
  PASSING_BEFORE=$(count_passing)
  START_TIME=$(date +%s)

  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "  Stories passing: $PASSING_BEFORE / $TOTAL_STORIES"
  echo "==============================================================="

  # Run the selected tool with the ralph prompt
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    # Claude Code: use --dangerously-skip-permissions for autonomous operation, --print for output
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$SCRIPT_DIR/CLAUDE.md" 2>&1 | tee /dev/stderr) || true
  fi

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  PASSING_AFTER=$(count_passing)
  STORIES_COMPLETED=$((PASSING_AFTER - PASSING_BEFORE))

  # Guard: detect if agent completed more than 1 story
  if [ "$STORIES_COMPLETED" -gt 1 ]; then
    echo ""
    echo "!! WARNING: Agent completed $STORIES_COMPLETED stories in one iteration (expected 1)."
    echo "!! This violates the one-story-per-iteration rule."
    echo "!! Reverting prd.json to only accept 1 story advancement..."

    # Find which stories were flipped and revert all but the first one
    NEWLY_PASSING=$(jq -r --argjson before "$PASSING_BEFORE" '
      [.userStories[] | select(.passes == true)] |
      .[$before:] |
      .[1:] |
      .[].id
    ' "$PRD_FILE" 2>/dev/null)

    for STORY_ID in $NEWLY_PASSING; do
      echo "   Reverting $STORY_ID to passes: false"
      jq --arg id "$STORY_ID" '
        .userStories |= map(if .id == $id then .passes = false else . end)
      ' "$PRD_FILE" > "$PRD_FILE.tmp" && mv "$PRD_FILE.tmp" "$PRD_FILE"
    done

    echo "!! Only the first completed story was kept. Continuing with next iteration."
    PASSING_AFTER=$(count_passing)
    STORIES_COMPLETED=$((PASSING_AFTER - PASSING_BEFORE))
  fi

  # ─── Judge review (only when a story was marked as passing) ──────
  JUDGE_VERDICT="n/a"

  if [ "$STORIES_COMPLETED" -eq 1 ]; then
    # Find which story was completed
    COMPLETED_STORY=$(jq -r --argjson before "$PASSING_BEFORE" '
      [.userStories[] | select(.passes == true)] |
      .[$before:] |
      .[0].id
    ' "$PRD_FILE" 2>/dev/null)

    JUDGE_VERDICT=$(run_judge "$COMPLETED_STORY") || true

    if [[ "$JUDGE_VERDICT" == FAIL* ]]; then
      FAIL_REASON="${JUDGE_VERDICT#FAIL:}"

      echo ""
      echo "  >> Judge REJECTED $COMPLETED_STORY — reverting"

      # Revert passes: true → false
      jq --arg id "$COMPLETED_STORY" '
        .userStories |= map(if .id == $id then .passes = false else . end)
      ' "$PRD_FILE" > "$PRD_FILE.tmp" && mv "$PRD_FILE.tmp" "$PRD_FILE"

      # Revert the commit (keep history clean)
      git reset --soft HEAD~1 2>/dev/null || true
      git checkout -- . 2>/dev/null || true
      git clean -fd 2>/dev/null || true

      PASSING_AFTER=$(count_passing)
      STORIES_COMPLETED=0

      # Log judge feedback to progress.txt so next iteration knows what to fix
      {
        echo ""
        echo "## $(date '+%Y-%m-%d %H:%M') - JUDGE REJECTED $COMPLETED_STORY"
        echo "- **Reason:** $FAIL_REASON"
        echo "- Agent must address this feedback on next attempt"
        echo "---"
      } >> "$PROGRESS_FILE"

      # Track retries
      inc_retry_count "$COMPLETED_STORY"

      if [ "$(get_retry_count "$COMPLETED_STORY")" -ge "$MAX_RETRIES" ]; then
        echo ""
        echo "!! HARD STOP: Story $COMPLETED_STORY failed judge review $MAX_RETRIES times."
        echo "!! All previous passing stories are preserved."
        echo ""
        echo "Stories passing: $(count_passing) / $TOTAL_STORIES"
        echo "Failed story: $COMPLETED_STORY"
        echo "Reason: $FAIL_REASON"
        echo ""
        echo "To resume after fixing manually:"
        echo "  ./ralph.sh --tool $TOOL $MAX_ITERATIONS"

        log_metric "$i" "$COMPLETED_STORY" "0" "$DURATION" "$PASSING_BEFORE" "$PASSING_AFTER" "FAIL_HARD_STOP"
        exit 1
      else
        echo "  >> Will retry $COMPLETED_STORY (attempt $(get_retry_count "$COMPLETED_STORY")/$MAX_RETRIES)"
      fi
    fi
  elif [ "$STORIES_COMPLETED" -eq 0 ]; then
    # Agent didn't complete any story — track as failed attempt
    # Try to figure out which story it was working on
    ATTEMPTED_STORY=$(jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0].id' "$PRD_FILE" 2>/dev/null)

    if [ -n "$ATTEMPTED_STORY" ]; then
      inc_retry_count "$ATTEMPTED_STORY"

      if [ "$(get_retry_count "$ATTEMPTED_STORY")" -ge "$MAX_RETRIES" ]; then
        echo ""
        echo "!! HARD STOP: Story $ATTEMPTED_STORY failed to complete $MAX_RETRIES times."
        echo "!! All previous passing stories are preserved."
        echo ""
        echo "Stories passing: $(count_passing) / $TOTAL_STORIES"
        echo "Failed story: $ATTEMPTED_STORY"
        echo ""
        echo "To resume after fixing manually:"
        echo "  ./ralph.sh --tool $TOOL $MAX_ITERATIONS"

        log_metric "$i" "$ATTEMPTED_STORY" "0" "$DURATION" "$PASSING_BEFORE" "$PASSING_AFTER" "FAIL_HARD_STOP"
        exit 1
      fi
    fi
  fi

  # Log metrics
  log_metric "$i" "${COMPLETED_STORY:-unknown}" "$STORIES_COMPLETED" "$DURATION" "$PASSING_BEFORE" "$PASSING_AFTER" "$JUDGE_VERDICT"

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    # Double-check that all stories are actually passing
    FINAL_PASSING=$(count_passing)
    if [ "$FINAL_PASSING" -eq "$TOTAL_STORIES" ]; then
      echo ""
      echo "Ralph completed all tasks!"
      echo "Completed at iteration $i of $MAX_ITERATIONS"
      echo ""
      echo "Next steps:"
      echo "  1. Review changes on the feature branch"
      echo "  2. Squash WIP commits into one: git rebase -i main"
      echo "  3. Rename commit to: f/<ticket> - <description>"
      echo "  4. Push and open PR"
      exit 0
    else
      echo ""
      echo "Agent claimed COMPLETE but only $FINAL_PASSING/$TOTAL_STORIES stories pass."
      echo "Continuing iterations..."
    fi
  fi

  # Trim progress if needed (check every 5 iterations)
  if (( i % 5 == 0 )); then
    trim_progress
  fi

  # ─── Iteration Summary ────────────────────────────────────────────
  CURRENT_PASSING=$(count_passing)
  DURATION_MIN=$((DURATION / 60))
  DURATION_SEC=$((DURATION % 60))

  # Build progress bar
  PROGRESS_BAR=""
  for p in $(seq 1 $TOTAL_STORIES); do
    if [ "$p" -le "$CURRENT_PASSING" ]; then
      PROGRESS_BAR="${PROGRESS_BAR}█"
    else
      PROGRESS_BAR="${PROGRESS_BAR}░"
    fi
  done

  echo ""
  echo "┌─────────────────────────────────────────────────────────────────┐"
  echo "│  ITERATION $i SUMMARY                                          "
  echo "├─────────────────────────────────────────────────────────────────┤"

  # What happened this iteration
  if [ "$STORIES_COMPLETED" -eq 1 ]; then
    STORY_TITLE=$(jq -r --arg id "$COMPLETED_STORY" '.userStories[] | select(.id == $id) | .title' "$PRD_FILE" 2>/dev/null)
    if [[ "$JUDGE_VERDICT" == FAIL* ]]; then
      echo "│  ✗ $COMPLETED_STORY — $STORY_TITLE"
      echo "│    Judge rejected: ${JUDGE_VERDICT#FAIL:}"
    else
      echo "│  ✓ $COMPLETED_STORY — $STORY_TITLE"
    fi
  else
    ATTEMPTED_TITLE=$(jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0] | "\(.id) — \(.title)"' "$PRD_FILE" 2>/dev/null)
    echo "│  ✗ No story completed (attempted: $ATTEMPTED_TITLE)"
  fi

  echo "│"
  echo "│  Progress: [$PROGRESS_BAR] $CURRENT_PASSING / $TOTAL_STORIES"
  echo "│  Duration: ${DURATION_MIN}m ${DURATION_SEC}s"

  # Show remaining stories
  REMAINING=$(jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[] | "│    · \(.id) — \(.title)"' "$PRD_FILE" 2>/dev/null)
  if [ -n "$REMAINING" ]; then
    echo "│"
    echo "│  Remaining:"
    echo "$REMAINING"
  fi

  echo "└─────────────────────────────────────────────────────────────────┘"
  echo ""
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Stories passing: $(count_passing) / $TOTAL_STORIES"
echo "Check $PROGRESS_FILE for status."
echo "Check $METRICS_FILE for performance data."
exit 1
