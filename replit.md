# enxOS

Flutter/Dart mobile app for the enxOS identity hub and its isolated Inasx, Pigeon, and FreeMarket modules.

## Run & Operate

- `flutter pub get` — install Flutter dependencies
- `flutter run` — run the Flutter app on a connected device/emulator
- `flutter build apk --release` — build an Android release APK
- `.github/workflows/android_build.yml` — build and upload the APK on pushes to `main` or manual dispatch
- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env: `DATABASE_URL` — Postgres connection string

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- Flutter/Dart app at the repository root
- `provider` for `AuthState` and isolated `ModuleState`
- `flutter_foreground_task` for the Android foreground-service notification
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)

## Where things live

- `lib/core/enxos/` — auth/session states, dashboard, unlock flow, and foreground-service handler
- `lib/modules/{inasx,pigeon,freemarket}/` — module-specific screen entry points
- `android/` and `web/` — Flutter platform projects
- `pubspec.yaml` — Flutter dependencies and app metadata
- `.github/workflows/android_build.yml` — Android APK CI
- `lib/api-spec/openapi.yaml` — shared API contract
- `lib/db/src/schema/` — shared API database schema

## Architecture decisions

- enxOS and per-module sessions are separate state providers; signing out clears all module sessions.
- Identity repositories currently use demo-only validators; connect real server-side validation before production.
- Private IDs are transient form inputs and are not saved in application session state.
- The foreground service is opt-in and uses Android `dataSync`; Android 15+ imposes a six-hour-per-24-hour limit for that service type.

## Product

The app provides a global enxOS sign-in, a dashboard for three secondary modules, a separate credential challenge before each module opens, and an optional persistent Android foreground notification.

## User preferences

- Keep the app in Flutter/Dart with modular folders for enxOS, Inasx, Pigeon, and FreeMarket.

## Gotchas

_Populate as you build — sharp edges, "always run X before Y" rules._

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
