# progress.txt Template

Generate this file in the target project's root. Pre-populate with detected codebase patterns so Ralph's first iteration starts with context.

---

## Template

```
# Ralph Progress Log
Started: {YYYY-MM-DD}
---

## Codebase Patterns
{All HIGH confidence detections, formatted as actionable rules}
- Use {package_manager} as package manager
- {language} {version_detail, e.g., "strict mode — all types explicit"}
- {framework} — {router/architecture detail, e.g., "App Router, pages in app/"}
- {styling, e.g., "Tailwind CSS for all styling — no CSS files"}
- {ORM, e.g., "Prisma ORM — schema in prisma/schema.prisma"}
- {state, e.g., "Zustand for client state — stores in src/stores/"}
- {data_fetching, e.g., "TanStack Query for server state"}
- {auth, e.g., "NextAuth for authentication — config in src/auth.ts"}
- {naming, e.g., "Files: kebab-case, Components: PascalCase"}
- {imports, e.g., "Use @/ alias for src/ imports"}
- {quality, e.g., "Run pnpm typecheck && pnpm lint && pnpm test before commit"}
- {conventions from Q19 if provided}
---
```

---

## Generation Rules

1. **Only include HIGH confidence detections.** MEDIUM/LOW items should be phrased as observations, not rules.
2. **Each pattern must be actionable.** "TypeScript" is not useful. "TypeScript strict mode — all types must be explicit, no `any`" is useful.
3. **Include the quality command as a pattern.** This is the single most important thing for Ralph to know.
4. **Order matters:** Put the most fundamental patterns first (package manager, language, framework) and conventions last.
5. **Keep it to 8-15 patterns.** Too many dilutes signal. If detection found 20+ things, consolidate related items.
6. **This is the bootstrapping value of brownfield-init.** Without this file, Ralph's first iteration starts blind. With it, Ralph immediately knows the codebase conventions.
