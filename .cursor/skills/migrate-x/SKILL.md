---
name: migrate-x
description: Maintains the Migrate X monorepo (Dart backend + Flutter frontend). Use when adding features, routes, services, screens, providers, widgets, or models to the project. Also use when asked about the project architecture, running the app, or extending the migration tool.
---

# Migrate X Development

## Project Overview

Migrate X is a Flutter code migration tool. Backend accepts a Flutter/Dart project as a zip, analyzes it, generates a migration plan with per-file diffs. Frontend is a single-page pipeline that progressively reveals upload, analysis, diff review (with accept/decline per file), and download sections.

## Directory Map

```
backend/
  bin/server.dart              — entry point, mounts routes, starts shelf server
  lib/config.dart              — reads PORT, WORKSPACE_PATH from .env
  lib/cors.dart                — CORS middleware
  lib/logger.dart              — request logging middleware
  lib/exceptions.dart          — AppException(statusCode, message)
  lib/services/                — business logic (zip, analyzer, patch, git, migration)
    patch_service.dart         — FileDiff model + dummy per-file diffs
    migration_service.dart     — MigrationPlanResult with List<FileDiff>
  lib/routes/                  — HTTP handlers (upload, analysis, migration, download)

frontend/
  lib/main.dart                — ProviderScope + app entry
  lib/app.dart                 — MaterialApp, M3 theme, uses AppRoutes
  lib/routes/app_routes.dart   — single route: home (/)
  lib/models/                  — data classes with fromJson
    migration_plan.dart        — MigrationPlan + FileDiff (filename, oldText, newText)
    analysis_result.dart       — AnalysisResult
  lib/providers/api_provider.dart — shared Provider for ApiService
  lib/services/api_service.dart — HTTP client for backend
  lib/widgets/                 — shared reusable widgets (package_list_tile)
  lib/screens/home/            — single-page pipeline:
    home_screen.dart           — ConsumerStatefulWidget with 4 sections + auto-scroll
    pipeline_provider.dart     — PipelineState, PipelineStage, PipelineNotifier
    upload_button.dart         — file picker + upload trigger
    analysis_card.dart         — severity icon + issue details
    diff_viewer.dart           — PrettyDiffText wrapper
```

## Pipeline Flow

1. **Upload** — user picks a .zip, `PipelineNotifier.upload()` sends it to backend.
2. **Analysis** — auto-triggered after upload, fetches analysis results.
3. **Migration** — auto-triggered after analysis, fetches per-file diffs.
4. **Review** — each file diff shown with Accept/Decline buttons.
5. **Download** — auto-revealed after all files reviewed; downloads migrated zip.

Auto-scroll uses `GlobalKey`s + `Scrollable.ensureVisible` on stage transitions.

## How to Add a Backend Route

1. Create `backend/lib/routes/<name>_routes.dart`.
2. Export a function: `Router <name>Routes(ServiceDep dep)` that returns a `Router`.
3. Add handlers, catch `AppException`, return JSON.
4. In `bin/server.dart`, instantiate the service and mount: `..mount('/<path>', <name>Routes(dep).call)`.

```dart
Router healthRoutes() {
  final router = Router();
  router.get('/', (Request request) => Response.ok('{"status":"ok"}',
      headers: {'Content-Type': 'application/json'}));
  return router;
}
```

## How to Add a Backend Service

1. Create `backend/lib/services/<name>_service.dart`.
2. Define a class with a constructor accepting config or dependencies.
3. Add methods. Mark future LLM integration points with `// TODO:`.
4. Inject into routes from `bin/server.dart`.

## How to Add a Pipeline Section

1. Add a new stage to `PipelineStage` enum in `pipeline_provider.dart`.
2. Add corresponding state fields to `PipelineState` and logic to `PipelineNotifier`.
3. Add a `_build<Section>` method in `home_screen.dart` gated by the new stage.
4. Add a `GlobalKey` and auto-scroll entry for the new stage.

## How to Add a Shared Provider

1. Create `frontend/lib/providers/<name>_provider.dart`.
2. Use for cross-feature state (e.g. `ApiService`).

## How to Add a Shared Widget

1. Create `frontend/lib/widgets/<name>.dart`.
2. Prefer `StatelessWidget` or `ConsumerWidget`.
3. Accept data via constructor parameters.
4. Use M3 components (`Card`, `FilledButton`, `ListTile`).

## How to Add a Model

1. Create `frontend/lib/models/<name>.dart`.
2. Define fields, constructor, and `factory fromJson(Map<String, dynamic> json)`.

## Running the Project

```bash
# Backend
cd backend && cp .env.example .env && dart pub get && dart run bin/server.dart

# Frontend
cd frontend && flutter pub get && flutter run
```

## Key Patterns

- Backend error handling: throw `AppException`, catch in route, return JSON.
- Frontend pipeline state: `PipelineNotifier` auto-chains upload -> analysis -> migration.
- Per-file diff review: `fileDecisions` map tracks accept/decline per filename.
- Diff rendering: `PrettyDiffText(oldText:, newText:)` with monospace styling.
- Backend returns `List<FileDiff>` each with `filename`, `oldText`, `newText`.

## Technology Stack

| Layer    | Tech                                    |
|----------|-----------------------------------------|
| Backend  | Dart, shelf, shelf_router, dotenv, archive, process_run |
| Frontend | Flutter, flutter_riverpod, http, file_picker, pretty_diff_text |
| Theme    | Material 3, ColorScheme.fromSeed(indigo) |
