# AGENTS.md Template

Generate this file in the target project's root. Replace all `{placeholders}` with detected/interview values.

---

## Template

```markdown
# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs coding agents repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, progress.txt, and prd.json.

## Commands

\`\`\`bash
# Development
{dev_command}

# Quality checks
{quality_commands}

# Run Ralph
./ralph.sh --tool claude [max_iterations]
\`\`\`

## Key Files

- `prd.json` — Current PRD with story completion status
- `progress.txt` — Iteration log with codebase patterns (READ THIS FIRST)
- `CLAUDE.md` — Agent instructions and project conventions
- `tasks/` — PRD documents and task files

## Your Task (Each Iteration)

1. Read `prd.json` and `progress.txt` (check Codebase Patterns section first)
2. Check you're on the correct branch from PRD `branchName`
3. Pick the **highest priority** story where `passes: false`
4. **Research** — Read acceptance criteria, find related files (grep keywords, trace imports), check progress.txt for relevant learnings
5. **Plan** — Decide which files to change, what approach, edge cases. If too complex for one iteration, note why and skip to next story
6. **Implement** — Execute the plan. Stay focused on planned changes, don't drift
7. Run quality checks: `{quality_check_commands}`
8. If checks pass, commit: `feat: [Story ID] - [Story Title]`
9. Update `prd.json` to set `passes: true`
10. Append progress to `progress.txt`

## Project-Specific Patterns

{From auto-detection and interview — the most important patterns for this specific project}
- {e.g., Use `@/` import alias for all src/ imports}
- {e.g., Server actions go in `src/app/actions/` — one file per domain}
- {e.g., All database queries go through Prisma — never raw SQL}
- {e.g., Components use Tailwind — no inline styles or CSS files}

## Quality Requirements

{From Q10 and Q11}
- Run `{typecheck_command}` before every commit
- Run `{lint_command}` before every commit
{if tests required from Q11}
- Run `{test_command}` — tests must pass
- Add tests for new logic when possible
{/if}
{if no tests from Q11}
- Tests not required but appreciated for complex logic
{/if}
- Do NOT commit broken code
- Keep changes focused and minimal

## Progress Report Format

APPEND to progress.txt (never replace):
\`\`\`
## [Date/Time] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---
\`\`\`

## Consolidate Patterns

If you discover a reusable pattern, add it to the `## Codebase Patterns` section at the TOP of progress.txt. Only add patterns that are general and reusable, not story-specific.

{if browser testing from Q21}
## Browser Testing

For UI stories with "Verify in browser using dev-browser skill" in acceptance criteria:
1. Start dev server: `{dev_command}`
2. Navigate to the relevant page
3. Verify UI changes work as expected
4. Note any visual issues in progress report
{/if}

## Stop Condition

After completing a story, check if ALL stories have `passes: true`. If so, reply with:
<promise>COMPLETE</promise>
```

---

## Generation Rules

1. **Quality commands must match CLAUDE.md exactly.** Don't have different commands in the two files.
2. **Project-Specific Patterns are the highest-value section.** Include 4-8 concrete, actionable patterns from detection.
3. **Keep the iteration task list identical** to the standard Ralph format — don't customize the workflow steps.
4. **Browser testing section only if Q21 indicates it's needed.**
