# CLAUDE.md Template

Generate this file in the target project's root. Replace all `{placeholders}` with detected/interview values. Omit sections that don't apply.

---

## Template

```markdown
# {Project Name} - Agent Instructions

## Tech Stack
- **Language:** {language} {version if known}
- **Framework:** {framework} {version}
- **Styling:** {styling approach}
- **Database:** {database} via {ORM}
- **Testing:** {test framework} (unit), {e2e framework} (E2E)
- **Package Manager:** {package manager}
{if monorepo}- **Monorepo:** {tool} ({package list}){/if}

## Quality Commands

Run these before every commit:

\`\`\`bash
{package_manager} run typecheck    # {actual command from scripts}
{package_manager} run lint          # {actual command from scripts}
{package_manager} run test          # {actual command from scripts}
\`\`\`

{if additional commands from CI or Q10}
Additional checks:
\`\`\`bash
{additional commands}
\`\`\`
{/if}

## Project Structure

\`\`\`
{2-level directory tree with purpose annotations}
src/
  app/          # Next.js App Router pages and layouts
  components/   # Shared UI components
  lib/          # Utilities and helpers
  actions/      # Server actions
prisma/         # Database schema and migrations
public/         # Static assets
\`\`\`

## Codebase Patterns

{Discovered patterns from auto-detection and interview}
- {e.g., Import alias: use `@/` for src/ imports}
- {e.g., Components: co-located with styles, one component per file}
- {e.g., API: server actions in `src/app/actions/`, no API routes}
- {e.g., State: Zustand stores in `src/stores/`, one store per domain}
- {e.g., Data fetching: TanStack Query for all server data}

## Conventions

- **File naming:** {detected convention, e.g., kebab-case for files, PascalCase for components}
- **Commit messages:** {format from Q13, e.g., Conventional Commits (feat:/fix:/chore:)}
- **Branch naming:** {from Q12, e.g., feature/description, fix/description}
- **Imports:** {style, e.g., named imports preferred, use @/ alias}
{if barrel exports}- **Barrel exports:** index.ts files re-export public API from each module{/if}

## Do NOT

{Critical constraints from Q19 and detection}
- Do NOT modify {protected files/directories}
- Do NOT commit .env files
- Do NOT skip type checking
{any additional rules from user's Q19 answer}

## Environment Setup

\`\`\`bash
{package_manager} install
{copy env command, e.g., cp .env.example .env}
{db setup command, e.g., npx prisma db push}
{dev server command, e.g., pnpm dev}
\`\`\`

{if Q21 indicates browser testing}
## Browser Testing

For stories with UI changes, verify in browser:
- Dev server: `{dev command}`
- Base URL: `http://localhost:{port}`
{specific pages from Q21 if applicable}
{/if}
```

---

## Generation Rules

1. **Only include sections that apply.** No database section for a CLI tool. No browser testing for a backend service.
2. **Quality commands must be exact.** Copy directly from `package.json` scripts or the user's Q10 answer. Never guess.
3. **Directory tree should reflect actual structure.** Run a quick ls/glob to confirm directories exist before including them.
4. **Patterns section is high-value.** This is what Ralph reads every iteration. Be specific and actionable.
5. **Keep it under 80 lines.** Agents read this every iteration — conciseness matters.
