# Copilot Instructions — Samosprava Bytov

## Project overview
- Mobile Flutter app for apartment building management.
- Backend ecosystem is shared with the admin web dashboard, currently live at `sb.chudy.online`.
- The mobile app is being migrated from a legacy MVP state to a clean architecture with Riverpod and feature-first layers.

## Tech stack
- Flutter + Dart
- Riverpod for state management
- Clean Architecture with feature-first structure
- PHP backend endpoints for the web/admin ecosystem
- Secure token storage via `flutter_secure_storage`

## Current repository status
- The app is not yet in a production-ready release state.
- Legacy code remains in `lib/obrazovky/` and `lib/sluzby/`.
- Auth flow has been refactored to a new layered structure under `lib/features/auth/`.
- Dashboard flow has been introduced under `lib/features/dashboard/`.
- Routing and auth guards are being introduced via `lib/app/router.dart`.
- Production environment is not yet fully externalized; backend base URL must be defined via environment configuration rather than hardcoded values.

## Architectural direction
- Respect the planned feature-first structure:
  - `lib/features/<feature>/data`
  - `lib/features/<feature>/domain`
  - `lib/features/<feature>/presentation`
- UI must remain thin and read Riverpod providers; business and network logic must live in repositories/use cases/data sources.
- Auth state must be centrally managed via Riverpod providers and guarded with router checks.
- Shared config must live in `lib/core/config` and network code in `lib/core/network`.

## Release readiness checklist
- Remove hardcoded environment values from app code.
- Centralize API configuration in `AppConfig` and use `--dart-define` or equivalent environment injection.
- Keep secure tokens in `TokenStorage` only.
- Migrate remaining legacy screens to feature modules.
- Add automated tests for auth, dashboard, and core API interactions.
- Prepare Android/iOS signing, app metadata, and CI/CD release pipeline before production publish.

## Active implementation priorities
1. Complete auth flow and router guard.
2. Migrate dashboard screens and providers to the feature structure.
3. Add logout / session lifecycle handling.
4. Prepare clean feature modules for tickets, finance, and voting.
5. Prepare codemagic/GitHub Actions pipeline for build validation and release artifacts.

## Coding rules
- Use English for code identifiers and comments.
- Use Slovak for user-facing explanations and implementation commentary.
- Prefer immutable models and typed state.
- Use Riverpod `.when()` for async states and error/loading handling.
- Keep platform and backend details behind repositories and API client wrappers.

## Important repo notes
- App entry point: `lib/main.dart`
- Core config: `lib/core/config/app_config.dart`
- API wrapper: `lib/core/network/api_client.dart`
- Secure token storage: `lib/core/storage/token_storage.dart`
- Auth feature: `lib/features/auth/`
- Dashboard feature: `lib/features/dashboard/`
- Legacy screens still present under `lib/obrazovky/` until migration is complete.
