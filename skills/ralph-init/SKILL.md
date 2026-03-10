---
name: ralph-init
description: "Initialize Ralph for a new (greenfield) project. Sets up ralph.sh, CLAUDE.md, AGENTS.md, progress.txt, and tasks/ directory through a short interactive interview. Copies all scripts and makes them executable. Optionally accepts a feature description to also generate PRD + prd.json in one step. Use when starting a new project with Ralph from scratch. Triggers on: ralph init, initialize ralph, setup ralph, greenfield init, start ralph."
user-invocable: true
---

# Ralph Init (Greenfield)

Set up Ralph for a new or nearly-empty project. Copies all required scripts, generates configuration files, and prepares the project for autonomous iteration.

**If the user provides a feature description** (e.g., `/ralph-init Create a todo app with add/delete/toggle`), also generate the PRD and prd.json at the end — making the project ready to run Ralph immediately.

---

## The Job

Three phases (+ optional fourth), executed in order:

1. **Quick Scan** — Check what exists already (git repo? package.json? existing Ralph files?)
2. **Interview** — Ask 3 batches of targeted questions using `AskUserQuestion`
3. **Generate** — Copy scripts, create configuration files, set everything up
4. **PRD Generation (if description provided)** — Generate PRD markdown + prd.json from the user's feature description

**Important:** Phase 4 only runs if the user provided a feature description as an argument.

---

## Phase 1: Quick Scan

Before asking questions, silently check:

1. **Is this a git repo?** If not, warn the user and ask if they want to `git init`
2. **Does `prd.json` exist?** If yes, Ralph may already be configured — warn and ask to continue
3. **Does `progress.txt` exist?** Same as above
4. **Does `ralph.sh` or `scripts/ralph/` exist?** If yes, Ralph scripts are already present
5. **Does `CLAUDE.md` exist?** Read it if so — we'll merge, not overwrite
6. **Does `AGENTS.md` exist?** Same as above
7. **Does `package.json` exist?** Read for project name, scripts, deps — use detected values as defaults
8. **Count source files** — If >20 source files, suggest `/brownfield-init` instead (it has auto-detection)

Build a quick internal summary of what exists. Do NOT show raw scan output.

---

## Phase 2: Interview

Present scan summary first, then ask questions in 3 batches.

### Scan Summary

Show a brief overview:

```
## Project Scan

**Directory:** {cwd}
**Git:** {initialized / not initialized}
**Package manager:** {detected or unknown}
**Existing Ralph files:** {none / list found files}
**Source files:** {count} files detected
```

### Batch 1: Project Basics

**Always asked.** Use `AskUserQuestion` with 2-4 options.

| # | Question | Options |
|---|---|---|
| Q1 | What type of project is this? | Web app (React/Next.js/Vue) · API/backend service · CLI tool/library · Mobile app (React Native/Flutter) |
| Q2 | What tech stack will you use? | Next.js + TypeScript · React + Vite + TypeScript · Node.js + Express · Python + FastAPI |
| Q3 | What package manager? {show detected if found} | npm · pnpm · yarn · bun |
| Q4 | What database (if any)? | PostgreSQL (via Prisma) · SQLite (via Prisma) · MongoDB · None/decide later |

**Note on Q2:** If `package.json` was detected with deps, show detected stack as first option with "(Detected)" suffix. If user picks "Other", wait for free-form response.

### Batch 2: Quality & Workflow

**Always asked.**

| # | Question | Options |
|---|---|---|
| Q5 | What quality checks should Ralph run before commits? | Typecheck + lint + test · Typecheck + lint (no tests yet) · Just typecheck · Custom commands |
| Q6 | What commit message format? | Conventional Commits (feat:/fix:/chore:) · Simple descriptive messages · Gitmoji · Project-specific format |
| Q7 | Will this project have a UI that needs browser verification? | Yes — use dev-browser for UI stories · No — backend/CLI/library · Not yet — will configure later |

### Batch 3: Ralph Configuration

**Always asked.**

| # | Question | Options |
|---|---|---|
| Q8 | Where should Ralph scripts live? | `scripts/ralph/` (recommended) · Project root · Custom location |
| Q9 | Which AI tool will you use with Ralph? | Claude Code · Amp · Both |
| Q10 | Anything else Ralph should know? | No, this covers everything · Yes, I have additional context · There are files/dirs Ralph should never touch |

**After Q10:** If user selects "Yes" or "files/dirs to never touch", wait for their free-form response and incorporate into CLAUDE.md.

---

## Phase 3: Generation

### Step 1: Copy Ralph Scripts

Determine the Ralph repo location. The skill is loaded from the Ralph repo, so use the skill's own path to find the source files.

**Find the ralph repo:** The skill file lives at `{ralph_repo}/skills/ralph-init/SKILL.md`. Navigate up two levels from the skill's location to find the ralph repo root.

Copy scripts to the location from Q8:

```bash
# Default: scripts/ralph/
mkdir -p {target_dir}
cp {ralph_repo}/ralph.sh {target_dir}/ralph.sh
chmod +x {target_dir}/ralph.sh
```

Copy the appropriate prompt file based on Q9:
- **Claude Code:** Copy `{ralph_repo}/CLAUDE.md` → `{target_dir}/CLAUDE.md`
- **Amp:** Copy `{ralph_repo}/prompt.md` → `{target_dir}/prompt.md`
- **Both:** Copy both files

Also copy:
- `{ralph_repo}/prd.json.example` → `{target_dir}/prd.json.example`
- `{ralph_repo}/judge-prompt.md` → `{target_dir}/judge-prompt.md`

**CRITICAL: All files in Step 1 MUST be verbatim copies from the ralph repo using `cp`. NEVER generate, rewrite, or modify their content. These are exact operational files that `ralph.sh` depends on (e.g., CLAUDE.md is fed directly to claude via stdin). If you generate or alter them, Ralph will break.**

### Step 2: Generate Project CLAUDE.md

Generate `CLAUDE.md` in the **project root** (NOT in scripts/ralph/). This is the project-specific agent instructions file.

Use interview answers to fill in. Keep it concise (<80 lines). Structure:

```markdown
# {Project Name} - Agent Instructions

## Tech Stack
- **Language:** {from Q2}
- **Framework:** {from Q2}
- **Package Manager:** {from Q3}
- **Database:** {from Q4}

## Quality Commands

Run these before every commit:

```bash
{commands from Q5 — use actual script names if package.json detected}
```

## Project Structure

```
{Basic starter structure based on Q2 — e.g., src/, tests/, etc.}
```

## Conventions

- **File naming:** {sensible default for chosen stack, e.g., kebab-case}
- **Commit messages:** {from Q6}
- **Imports:** {sensible default, e.g., use @/ alias for src/}

## Do NOT

- Do NOT commit .env files
- Do NOT skip type checking
{from Q10 if user specified protected files/dirs}

{if Q7 indicates browser testing}
## Browser Testing

For stories with UI changes, verify in browser:
- Dev server: `{dev command}`
- Base URL: `http://localhost:{port}`
{/if}
```

### Step 3: Generate AGENTS.md

Generate `AGENTS.md` in the **project root**. Use the standard Ralph template:

```markdown
# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop. Each iteration picks one story, implements it, and commits. Memory persists via git history, progress.txt, and prd.json.

## Commands

```bash
# Development
{dev_command from stack}

# Quality checks
{quality_commands from Q5}

# Run Ralph
./{scripts_dir}/ralph.sh --tool {tool from Q9} [max_iterations]
```

## Key Files

- `prd.json` — Current PRD with story completion status
- `progress.txt` — Iteration log with codebase patterns (READ THIS FIRST)
- `CLAUDE.md` — Agent instructions and project conventions
- `tasks/` — PRD documents and task files

## Quality Requirements

- Run quality checks before every commit
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns
```

### Step 4: Create Supporting Files

1. **`progress.txt`** in project root:
```
# Ralph Progress Log
Started: {YYYY-MM-DD}
---

## Codebase Patterns
- Use {package_manager} as package manager
- {language} with {framework}
- Quality check: {quality command from Q5}
---
```

2. **`tasks/` directory** — Create if it doesn't exist

3. **`.gitignore` additions** — Append if not already present:
```
# Ralph
ralph-metrics.csv
.last-branch
```

### Step 5: Update ralph.sh Paths

The copied `ralph.sh` uses `SCRIPT_DIR` for relative paths, which should work correctly from its new location. Verify by reading the copied file and confirming `SCRIPT_DIR` resolution is correct.

**CRITICAL:** `ralph.sh` looks for `prd.json` and `progress.txt` relative to `SCRIPT_DIR`. Since the project's `prd.json` and `progress.txt` live in the project root (NOT in scripts/ralph/), update the copied `ralph.sh` to point to the project root:

```bash
# In the copied ralph.sh, update these lines:
PRD_FILE="$SCRIPT_DIR/../../prd.json"        # or appropriate relative path
PROGRESS_FILE="$SCRIPT_DIR/../../progress.txt"
```

Calculate the correct relative path based on the depth of Q8's answer relative to project root.

---

## Merge Rules

**Never overwrite existing files.** If CLAUDE.md or AGENTS.md already exists:

1. Read the existing file first
2. Identify sections that are NEW (not already covered)
3. Present a merge plan to the user
4. Ask for confirmation before writing
5. Append new sections below existing content, marked:

```markdown
## --- Added by Ralph Init ---

[new sections here]
```

If `progress.txt` exists, append Codebase Patterns at top (below header).

---

## Output Checklist

Before finishing, verify:

- [ ] Ralph scripts copied to {scripts_dir} and executable
- [ ] CLAUDE.md exists in project root with tech stack and quality commands
- [ ] AGENTS.md exists in project root with Ralph operational instructions
- [ ] progress.txt exists with Codebase Patterns section
- [ ] `tasks/` directory exists
- [ ] `.gitignore` updated with Ralph entries
- [ ] ralph.sh paths point to project root correctly
- [ ] No existing files were overwritten

Print a summary:

```
## Ralph Initialization Complete

**Scripts installed to:** {scripts_dir}/
  - ralph.sh (executable)
  - CLAUDE.md / prompt.md (prompt template)
  - prd.json.example (reference)
  - judge-prompt.md (optional judge)

**Project files generated:**
  - CLAUDE.md — Agent instructions for {project}
  - AGENTS.md — Ralph operational config
  - progress.txt — Ready for iteration logs
  - tasks/ — Ready for PRDs

**Next steps:**
1. Review generated files and adjust as needed
2. Create a PRD: `/prd`
3. Convert to prd.json: `/ralph`
4. Run Ralph: `./{scripts_dir}/ralph.sh --tool {tool} 10`
```

---

## Phase 4: PRD Generation (Optional)

**This phase only runs if the user provided a feature description as an argument to `/ralph-init`.**

If the user invoked the skill with a description (e.g., `/ralph-init Create a todo app with React, add/delete/toggle todos`), generate both the PRD markdown and prd.json automatically.

### Step 1: Generate PRD Markdown

Using the user's description and the interview answers (tech stack, quality commands, etc.), generate a PRD following the same format as the `/prd` skill:

- Save to `tasks/prd-[feature-name].md`
- Include: Introduction, Goals, User Stories, Functional Requirements, Non-Goals
- User stories must be small enough for one Ralph iteration
- Acceptance criteria must be verifiable
- Always include "Typecheck passes" in every story
- For UI stories, include "Verify in browser using dev-browser skill"

**Use the tech stack context from the interview** to make stories more specific (e.g., if they chose React + Vite, reference actual file paths like `src/App.tsx`).

### Step 2: Generate prd.json

Convert the PRD to `prd.json` in the project root, following the `/ralph` skill format:

```json
{
  "project": "[Project Name from Q1/scan]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[User's feature description]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": ["..."],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Story ordering rules:**
1. Schema/database changes first
2. Backend logic second
3. UI components third
4. Polish/styling last

**Story sizing rule:** If you cannot describe the change in 2-3 sentences, split it into multiple stories.

### Step 3: Update Summary

Replace the "Next steps" in the output summary:

```
**Next steps:**
1. Review generated PRD at tasks/prd-[feature-name].md
2. Review prd.json — adjust stories if needed
3. Run Ralph: ./{scripts_dir}/ralph.sh --tool {tool} 10
```

Instead of the default next steps that tell the user to run `/prd` and `/ralph` manually.

### No Description Provided

If the user runs `/ralph-init` without a description, skip Phase 4 entirely. The output summary should show the default next steps pointing to `/prd` and `/ralph`.

---

## Edge Cases

### Existing Ralph setup
If `ralph.sh` already exists in the expected location, ask the user:
> "Ralph scripts are already installed at {path}. Overwrite with latest version?"

### Large existing codebase (>20 source files)
Suggest brownfield-init instead:
> "This project has {N} source files. `/brownfield-init` can auto-detect your tech stack and conventions. Use brownfield-init instead?"

If user wants to continue with ralph-init anyway, proceed normally.

### No git repo
Offer to initialize:
> "This directory is not a git repo. Ralph requires git. Initialize now?"

If yes, run `git init` and create initial `.gitignore`.

### Monorepo / nested project
If the user is in a subdirectory of a larger repo, warn them that Ralph files will be created relative to the current directory. Ask if they want to initialize at the repo root instead.

### Custom scripts location
If Q8 answer is a custom path, validate it's within the project and create necessary parent directories.
