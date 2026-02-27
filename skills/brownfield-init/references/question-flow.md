# Question Flow Reference

22 questions in 5 batches. All use `AskUserQuestion` with 2-4 options (tool auto-adds "Other").

Present detected values as the first option labeled with "(Detected)" suffix. Skip questions entirely when detection confidence is HIGH and the answer is unambiguous.

---

## Batch 1: Project Overview

**Always asked.** Up to 4 questions per `AskUserQuestion` call.

| # | Question | Options |
|---|---|---|
| Q1 | What is the primary purpose of this project? | SaaS/web app · Developer tool/CLI/library · Mobile app · API/backend service |
| Q2 | What is the current state of this codebase? | Early stage (core building) · Mid stage (adding features) · Mature (maintenance + features) · Legacy (needs refactoring) |
| Q3 | Who will be working with Ralph on this project? | Solo developer · Small team (2-4) · Medium team (5-10) · Large team (10+) |
| Q4 | What will Ralph primarily be doing? | Building new features · Fixing bugs · Refactoring/improving code · Mixed - all of above |

---

## Batch 2: Architecture

**Conditional** — skip any question where auto-detection has HIGH confidence. Ask remaining questions.

| # | Question | Condition | Options |
|---|---|---|---|
| Q5 | How is the source code organized? | Structure unclear | Feature-based (code grouped by feature) · Layer-based (controllers/services/models) · Domain-driven (bounded contexts) · Hybrid |
| Q6 | How are components organized? | Frontend detected | Co-located (component + styles + tests together) · Separated by type (all components/, all styles/) · Feature folders + shared lib · Atomic design (atoms/molecules/organisms) |
| Q7 | What API pattern does this project use? | Backend detected | REST handlers · tRPC · GraphQL · Server actions |
| Q8 | How are database changes managed? | ORM detected | ORM migrations (generate + run) · Raw SQL migrations · Auto-sync/push (dev only) · No database |
| Q9 | How are packages related? | Monorepo detected | Independent (separate publish) · Shared libraries (internal deps) · Micro-frontends · Mixed |

---

## Batch 3: Quality & Workflow

**Always asked.** Show detected values where available.

| # | Question | Options |
|---|---|---|
| Q10 | What commands verify code quality? {show detected scripts} | Use detected scripts (Detected) · Custom commands · No formal checks (just typecheck) |
| Q11 | What is the testing approach? | Unit tests required for new code · Integration/E2E tests primary · Nice-to-have, not required · No tests - skip testing |
| Q12 | What branching model does this project use? | Feature branches + PR · Gitflow (develop/release/hotfix) · Trunk-based (commit to main) |
| Q13 | What commit message format? | Conventional Commits (feat:/fix:/chore:) · Gitmoji · Simple descriptive messages · Project-specific format |
| Q14 | How should Ralph handle PRs? | Create PR, human reviews · Auto-merge if CI passes · No PRs, commit directly to branch · Configure later |

---

## Batch 4: Codebase-Specific

**Conditional** on detected stack. Skip irrelevant questions entirely.

| # | Question | Condition | Options |
|---|---|---|---|
| Q15 | What styling approach does this project use? {show detected} | Frontend detected | Tailwind CSS (Detected) · CSS Modules · CSS-in-JS (styled-components/emotion) · Global CSS/SCSS |
| Q16 | How is client-side state managed? {show detected} | Frontend detected | Built-in hooks/context only · {detected_lib} (Detected) · Server state (React Query/SWR) · Combination |
| Q17 | What is the authentication setup? {show detected} | Auth detected | {detected} fully configured (Detected) · {detected} partially set up · Custom auth implementation · No authentication |
| Q18 | How are environment variables managed? | Always | .env files + .env.example committed · Platform-specific (Vercel/Railway env) · Config files in repo · Mix of approaches |
| Q19 | Are there critical conventions Ralph MUST follow? | Always | Yes - I'll describe them now · Follow existing patterns (auto-detect) · Follow linter rules strictly · No special conventions |

**Note on Q15-Q17:** Replace `{detected}` and `{detected_lib}` with actual detected values. If nothing was detected, use generic options without "(Detected)" labels.

---

## Batch 5: Ralph Configuration

**Always asked.**

| # | Question | Options |
|---|---|---|
| Q20 | What should Ralph's first tasks be? | I'll create PRDs manually · Identify tech debt (scan TODOs/FIXMEs) · I have a specific feature in mind · Run a codebase health check |
| Q21 | Does this project need browser verification for UI stories? | Yes, use dev-browser for all UI stories · Yes, but only for specific pages · No, this is backend/CLI/library · Not yet - will configure later |
| Q22 | Anything else Ralph should know about this project? | No, this covers everything · Yes, I have additional context · There are existing docs Ralph should read · There are files/dirs Ralph should never touch |

---

## Question Presentation Guidelines

### Before Each Batch
Briefly summarize what you learned from the previous batch and preview what the next batch covers:

> "Got it — {project} is a mid-stage SaaS with a small team. Now let me ask about the architecture..."

### Skipping Questions
When skipping due to HIGH confidence, tell the user:

> "Skipping architecture questions — I detected Next.js App Router with Prisma and server actions with high confidence. Let me know if that's wrong."

### After Q19 (Conventions)
If the user selects "Yes - I'll describe them now", wait for their free-form response and incorporate it into the generated CLAUDE.md under a "Conventions" or "Do NOT" section.

### After Q22 (Anything Else)
If the user selects "Yes, I have additional context" or "There are existing docs Ralph should read", wait for their response. If they point to docs, read those files and incorporate relevant information.

If "There are files/dirs Ralph should never touch", ask for the list and add it to the "Do NOT" section in CLAUDE.md.
