# Auto-Detection Reference

What to scan and how to interpret findings during Phase 1.

---

## 1A: Project Identity

Scan these files to identify the project:

| File | What to extract |
|---|---|
| `package.json` | name, description, scripts, dependencies, devDependencies, packageManager |
| `Cargo.toml` | name, version, dependencies |
| `pyproject.toml` | name, version, dependencies, build system |
| `go.mod` | module path, go version, dependencies |
| `Gemfile` | gem dependencies, ruby version |
| `pom.xml` | groupId, artifactId, dependencies |
| `composer.json` | name, require, require-dev |
| `README.md` | Project description, setup instructions, architecture notes |
| `CLAUDE.md` | Existing agent instructions (flag for merge) |
| `AGENTS.md` | Existing agent config (flag for merge) |
| `prd.json` | Existing Ralph PRD (flag — don't overwrite) |
| `progress.txt` | Existing progress log (flag for merge) |

---

## 1B: Tech Stack Detection

### Language & Runtime

| Signal | Detection | Confidence |
|---|---|---|
| `tsconfig.json` exists | TypeScript | HIGH |
| `.ts`/`.tsx` files present | TypeScript | MEDIUM |
| `pyproject.toml` or `requirements.txt` | Python | HIGH |
| `Cargo.toml` | Rust | HIGH |
| `go.mod` | Go | HIGH |
| `Gemfile` | Ruby | HIGH |
| `pom.xml` or `build.gradle` | Java/Kotlin | HIGH |
| `composer.json` | PHP | HIGH |

### Frontend Framework

| Signal | Detection | Confidence |
|---|---|---|
| `next` in deps + `app/` dir | Next.js App Router | HIGH |
| `next` in deps + `pages/` dir | Next.js Pages Router | HIGH |
| `next` in deps only | Next.js (router unknown) | MEDIUM |
| `react` in deps (no next) | React SPA | HIGH |
| `vue` in deps | Vue.js | HIGH |
| `svelte` or `@sveltejs/kit` in deps | Svelte/SvelteKit | HIGH |
| `@angular/core` in deps | Angular | HIGH |
| `astro` in deps | Astro | HIGH |
| `nuxt` in deps | Nuxt | HIGH |

### Backend Framework

| Signal | Detection | Confidence |
|---|---|---|
| `express` in deps | Express.js | HIGH |
| `fastify` in deps | Fastify | HIGH |
| `hono` in deps | Hono | HIGH |
| `@nestjs/core` in deps | NestJS | HIGH |
| `flask` or `django` in deps | Flask/Django | HIGH |
| `actix-web` or `axum` in Cargo.toml | Actix/Axum | HIGH |
| `gin` or `echo` in go.mod | Gin/Echo | HIGH |
| `rails` in Gemfile | Ruby on Rails | HIGH |
| `laravel` in composer.json | Laravel | HIGH |

### Styling

| Signal | Detection | Confidence |
|---|---|---|
| `tailwind.config.*` exists | Tailwind CSS | HIGH |
| `tailwindcss` in deps only | Tailwind CSS | MEDIUM |
| `*.module.css` files present | CSS Modules | HIGH |
| `styled-components` or `@emotion` in deps | CSS-in-JS | HIGH |
| `sass` or `scss` in deps | SCSS | HIGH |

### ORM / Database

| Signal | Detection | Confidence |
|---|---|---|
| `prisma/schema.prisma` exists | Prisma | HIGH |
| `drizzle.config.*` exists | Drizzle | HIGH |
| `typeorm` in deps | TypeORM | HIGH |
| `sequelize` in deps | Sequelize | HIGH |
| `sqlalchemy` in Python deps | SQLAlchemy | HIGH |
| `diesel` in Cargo.toml | Diesel | HIGH |
| `knex` in deps | Knex.js | HIGH |
| `mongoose` in deps | Mongoose (MongoDB) | HIGH |

### Testing

| Signal | Detection | Confidence |
|---|---|---|
| `vitest.config.*` exists | Vitest | HIGH |
| `jest.config.*` exists | Jest | HIGH |
| `vitest` in deps only | Vitest | MEDIUM |
| `jest` in deps only | Jest | MEDIUM |
| `playwright.config.*` exists | Playwright (E2E) | HIGH |
| `cypress.config.*` exists | Cypress (E2E) | HIGH |
| `pytest` in Python deps | pytest | HIGH |
| `go test` (Go project) | Go test | HIGH |

### Monorepo

| Signal | Detection | Confidence |
|---|---|---|
| `pnpm-workspace.yaml` exists | pnpm workspace | HIGH |
| `turbo.json` exists | Turborepo | HIGH |
| `nx.json` exists | Nx | HIGH |
| `lerna.json` exists | Lerna | HIGH |
| `workspaces` field in package.json | npm/yarn workspaces | HIGH |

### CI/CD

| Signal | Detection | Confidence |
|---|---|---|
| `.github/workflows/*.yml` exists | GitHub Actions | HIGH |
| `.gitlab-ci.yml` exists | GitLab CI | HIGH |
| `Jenkinsfile` exists | Jenkins | HIGH |
| `.circleci/config.yml` exists | CircleCI | HIGH |
| `vercel.json` exists | Vercel deployment | HIGH |
| `netlify.toml` exists | Netlify deployment | HIGH |

---

## 1C: Convention Detection

### File Naming
Sample 10-15 source files (not config files) and detect the dominant pattern:
- `kebab-case.ts` — kebab-case
- `camelCase.ts` — camelCase
- `PascalCase.ts` — PascalCase
- `snake_case.py` — snake_case

### Import Patterns
Check `tsconfig.json` for path aliases:
- `@/*` → path alias (note the base path)
- Relative imports only → no alias

Check a few source files for import style:
- Named imports vs default imports
- Barrel imports from `index.ts` files

### Barrel Exports
Count `index.ts` or `index.js` files. If >5 found, barrel exports are a convention.

### Package Manager
| Signal | Detection | Confidence |
|---|---|---|
| `pnpm-lock.yaml` exists | pnpm | HIGH |
| `yarn.lock` exists | yarn | HIGH |
| `package-lock.json` exists | npm | HIGH |
| `bun.lockb` or `bun.lock` exists | bun | HIGH |
| `packageManager` field in package.json | Whatever it specifies | HIGH |

### Scripts
Extract from `package.json` scripts:
- `dev` / `start` — development server command
- `build` — build command
- `test` — test command
- `lint` — lint command
- `typecheck` / `tsc` / `check` — type checking command
- `format` — formatting command

---

## 1D: Quality Tooling

| Signal | Detection | Confidence |
|---|---|---|
| `.eslintrc*` or `eslint.config.*` exists | ESLint | HIGH |
| `.prettierrc*` exists | Prettier | HIGH |
| `biome.json` or `biome.jsonc` exists | Biome | HIGH |
| `.husky/` directory exists | Husky pre-commit hooks | HIGH |
| `lint-staged` in package.json or `.lintstagedrc*` | lint-staged | HIGH |
| `.editorconfig` exists | EditorConfig | MEDIUM |

Extract quality commands from:
1. `package.json` scripts — look for `lint`, `format`, `typecheck`, `test` scripts
2. CI workflow files — look for `run:` steps that invoke quality tools
3. Husky hooks — read `.husky/pre-commit` for exact commands

---

## 1E: State & Data Layer

### State Management
| Signal | Detection | Confidence |
|---|---|---|
| `zustand` in deps | Zustand | HIGH |
| `@reduxjs/toolkit` or `redux` in deps | Redux | HIGH |
| `jotai` in deps | Jotai | HIGH |
| `recoil` in deps | Recoil | HIGH |
| `pinia` in deps | Pinia (Vue) | HIGH |
| `mobx` in deps | MobX | HIGH |

### Data Fetching
| Signal | Detection | Confidence |
|---|---|---|
| `@tanstack/react-query` in deps | TanStack Query | HIGH |
| `swr` in deps | SWR | HIGH |
| `@trpc/client` or `@trpc/server` in deps | tRPC | HIGH |
| `graphql` or `@apollo/client` in deps | GraphQL | HIGH |
| `axios` in deps | Axios (HTTP client) | MEDIUM |

### Authentication
| Signal | Detection | Confidence |
|---|---|---|
| `next-auth` or `@auth/core` in deps | NextAuth/Auth.js | HIGH |
| `@clerk/nextjs` or `@clerk/clerk-react` in deps | Clerk | HIGH |
| `auth0` in deps | Auth0 | HIGH |
| `lucia` in deps | Lucia | HIGH |
| `@supabase/supabase-js` in deps + auth usage | Supabase Auth | MEDIUM |
| `firebase` in deps + auth imports | Firebase Auth | MEDIUM |
| `passport` in deps | Passport.js | HIGH |

---

## Detection Report Format

Build the internal report as a structured object. Example:

```
Project: my-app
Description: "A task management SaaS"
Language: TypeScript (HIGH)
Frontend: Next.js 14, App Router (HIGH)
Backend: Server Actions + API routes (MEDIUM)
Styling: Tailwind CSS (HIGH)
ORM: Prisma (HIGH)
Database: PostgreSQL (inferred from Prisma schema) (MEDIUM)
Testing: Vitest (HIGH), Playwright (HIGH)
State: Zustand (HIGH)
Data Fetching: TanStack Query (HIGH)
Auth: NextAuth (HIGH)
Package Manager: pnpm (HIGH)
Monorepo: No
CI: GitHub Actions (HIGH)
Quality: ESLint (HIGH), Prettier (HIGH), Husky (HIGH)
File Naming: kebab-case (MEDIUM)
Import Alias: @/* → src/* (HIGH)
Barrel Exports: Yes (MEDIUM)
Scripts: dev=next dev, build=next build, test=vitest, lint=eslint ., typecheck=tsc --noEmit
Existing Ralph Files: None
```
