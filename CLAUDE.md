# CLAUDE.md — Flutter Template

This file provides context for Claude Code when working in any project built from `flutter_template`. It is the master reference for all technical decisions, conventions, and patterns.

## Starting a new app

If the user has just opened this directory and wants to build a new app, your first and only action is:

**Invoke `superpowers:brainstorming` before doing anything else.**

Do not write code, scaffold a project, or ask clarifying questions before brainstorming. The brainstorm produces the spec, the project CLAUDE.md, the module inclusion decisions, and the implementation plan — in that order. Nothing gets built until that output exists and the user has approved it.

See `processes/CLAUDE.md` for the full workflow. See `processes/bootstrap.md` for the bootstrapping steps that follow.

---

## What this is

A production-quality Flutter template for building iOS + Android apps. Based on the `fytter` fitness app codebase, stripped to generic infrastructure. Every significant decision has already been made — do not relitigate them.

## Tech stack (decided — do not propose alternatives)

| Concern | Choice |
|---|---|
| Framework | Flutter (iOS + Android) |
| Backend | Firebase (Auth + Firestore + Storage + Cloud Functions + Messaging) |
| State management | Riverpod 2.x |
| Navigation | GoRouter |
| Local database | Drift (SQLite ORM) |
| AI | LLM adapter via Cloud Functions (vendor-agnostic — see modules/ai/MODULE.md) |
| Theme | FlexColorScheme + custom token system in `lib/src/presentation/theme.dart` |
| Authentication | Firebase Auth + Google Sign-in |

## Architecture

Clean three-layer architecture. Dependencies flow inward only.

```
presentation/ → providers/ → domain/ ← data/
```

- `domain/` — entities and abstract repository interfaces. No Flutter imports.
- `data/` — concrete repository implementations, Drift database, Firebase integrations.
- `presentation/` — screens and widgets. Never import from `data/` directly.
- `providers/` — Riverpod providers. Bridge between layers.
- `services/` — standalone services (notifications, etc.) that don't belong to one layer.

## Modules

Each module is self-contained with its own `MODULE.md` in the `modules/` directory.
Before starting a new project, read each MODULE.md and decide: include or remove.
Follow the removal checklist in MODULE.md exactly.

Modules: `auth`, `database`, `notifications`, `ai`, `payments`, `onboarding`, `sync`

## Coding conventions

**Files and naming:**
- One widget per file. File name matches class name in snake_case.
- Feature screens live in `lib/src/presentation/<feature>/`
- Repository interfaces in `lib/src/domain/`
- Repository implementations in `lib/src/data/`
- Riverpod providers in `lib/src/providers/`

**Riverpod:**
- Use `Provider<T>` for singletons (database, repositories)
- Use `FutureProvider<T>` for async data
- Use `StreamProvider<T>` for real-time data
- Use `StateNotifier<State>` for stateful controllers
- Never use `ChangeNotifier`

**Navigation:**
- All routes defined in `lib/src/presentation/app_router.dart`
- Pass data between screens via `state.extra` with typed argument classes
- No direct Navigator.push() — always use GoRouter

**Database (Drift):**
- Define all tables in `lib/src/data/app_database.dart`
- Increment `schemaVersion` for every migration
- Never query Drift tables directly from presentation — always via repositories

**Cloud Functions:**
- All AI calls go through Cloud Functions. Never call an LLM API directly from Flutter.
- Use the adapter pattern in `functions/src/ai/`. See `example-function.ts` for the pattern.
- Callable functions only — no HTTP triggers.

**Theme:**
- All colours, typography, spacing, and radii from `lib/src/presentation/theme.dart` tokens.
- Access via `context.themeExt<AppColors>()` pattern (or equivalent theme extension).
- Never hardcode hex values or font sizes in widgets.

**Analytics:**
- Use `AppLogger.event(AppEvent.name)` for all analytics call sites
- Define event name constants in `AppEvent` in `lib/src/services/app_logger.dart`
- Never pass PII (user ID, email, name, health data) to `AppLogger`
- In debug builds, events print to console. In release, they go to Firebase Analytics.

## Adding a new feature

1. Define the domain entity in `lib/src/domain/`
2. Define the repository interface in `lib/src/domain/`
3. Implement the repository in `lib/src/data/`
4. Add the Drift table to `lib/src/data/app_database.dart` and increment `schemaVersion`
5. Run `dart run build_runner build --delete-conflicting-outputs`
6. Add Riverpod providers in `lib/src/providers/`
7. Build screens in `lib/src/presentation/<feature>/`
8. Add routes to `lib/src/presentation/app_router.dart`

## What not to do

- Do not use `Provider`, `BLoC`, `GetX`, or any state management other than Riverpod
- Do not import `data/` files from `presentation/` — go through providers
- Do not hardcode colours, font sizes, or spacing
- Do not call LLM APIs from Flutter — use Cloud Functions
- Do not add packages without checking if the functionality already exists in the template
- Do not use `Navigator.push()` — use GoRouter
