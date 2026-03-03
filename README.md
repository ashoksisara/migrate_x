# Migrate X

A Flutter code migration tool that accepts a Flutter/Dart project as a zip archive, analyzes it, shows a migration plan, and renders diffs.

## Project Structure

```
migrate_x/
  backend/          — Dart HTTP API server (shelf + shelf_router)
  frontend/         — Flutter app with Material 3 UI
```

### Backend (`backend/`)

Flat, modular Dart server using shelf and shelf_router.

- `bin/server.dart` — entry point, starts HTTP server
- `lib/config.dart` — environment config loaded from .env
- `lib/logger.dart` — request/response logging middleware
- `lib/exceptions.dart` — custom AppException class
- `lib/services/` — business logic (zip extraction, analysis, migration, patch generation)
- `lib/routes/` — HTTP route handlers (upload, analyze, migrate, download)

### Frontend (`frontend/`)

Flutter app using Riverpod for state management and Material 3 theming.

- `lib/main.dart` — app entry point with ProviderScope
- `lib/app.dart` — MaterialApp with M3 theme and named routes
- `lib/models/` — data classes (AnalysisResult, PackageInfo, MigrationPlan)
- `lib/providers/` — Riverpod providers (api, upload, analysis, migration)
- `lib/services/` — HTTP API client
- `lib/screens/` — HomeScreen, AnalysisScreen, DiffScreen
- `lib/widgets/` — reusable UI components

## Getting Started

### Prerequisites

- Dart SDK >= 3.11.0
- Flutter SDK >= 3.41.1

### Environment Setup

1. Copy the example environment file in the backend:

```bash
cd backend
cp .env.example .env
```

2. Edit `.env` to set your desired port and workspace path:

```
PORT=8080
WORKSPACE_PATH=./workspace
```

### Running the Backend

```bash
cd backend
dart pub get
dart run bin/server.dart
```

The server starts at `http://0.0.0.0:8080` by default.

### Running the Frontend

```bash
cd frontend
flutter pub get
flutter run
```

The app connects to `http://localhost:8080` by default. Update the base URL in `lib/providers/api_provider.dart` if your backend runs elsewhere.

## API Endpoints

| Method | Path             | Description                                |
|--------|------------------|--------------------------------------------|
| POST   | `/upload`        | Upload a .zip file, returns workspace id   |
| GET    | `/analyze/:id`   | Run dart analyze on the uploaded project   |
| GET    | `/migrate/:id`   | Get migration plan with diff               |
| GET    | `/download/:id`  | Download the workspace as a .zip file      |

## Docker (Backend)

```bash
cd backend
docker build -t migrate-x-backend .
docker run -p 8080:8080 migrate-x-backend
```
