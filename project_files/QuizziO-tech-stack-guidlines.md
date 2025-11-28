# CLAUDE.md - Quizzio OMR Scanner

## Architecture
- Clean Architecture: data → domain → presentation (never reverse imports)
- Repositories: interface in `domain/`, implementation in `data/`
- Inject via abstract types, never concrete classes

## BLoC/Cubit
- All states MUST extend `Equatable` with ALL fields in `props`
- Always check `if (isClosed) return;` before `emit()` after any `await`
- Use `Cubit` for CRUD, `Bloc` for multi-step flows (OMR scanning)
- States are immutable — always use `copyWith()`

## GetIt + Injectable
- Register: `getIt.registerLazySingleton<Interface>(() => Implementation())`
- Run `dart run build_runner build --delete-conflicting-outputs` after ANY annotation change
- Never call `getIt<T>()` inside widget `build()` methods

## Hive
- Register adapters BEFORE opening boxes
- Always use typed boxes: `Hive.box<Quiz>(name: 'quizzes')`
- Each `@HiveType(typeId: X)` must have unique X across all models
- Call `Hive.close()` on app lifecycle pause

## Camera
- Always `dispose()` CameraController
- Check permissions before initializing
- Use `ResolutionPreset.high` (not `max`) for OMR
- Lock orientation: `controller.lockCaptureOrientation(DeviceOrientation.portraitUp)`

## OpenCV Dart
- Use async variants: `cvtColorAsync`, `imreadAsync` (sync blocks UI)
- Always `dispose()` Mat objects after use
- Validate 4 corner markers detected before grading — abort if not found
- Use `adaptiveThreshold` for inconsistent lighting

## PDF Export
- Generate off main thread using `compute()`
- Use `path_provider` for file paths, never hardcode
- Verify file exists after write before sharing

## General Rules
- Null safety: use `?.` and `??`, never `!` without validation
- Log errors at catch point, not just rethrow
- Validate all external data (JSON templates, scan results)
- Use `async/await`, never `.then()`
- Prefer `final` over `var`, use `const` constructors

## Quick Reference

| ❌ Avoid | ✅ Use |
|----------|--------|
| `Hive.box()` | `Hive.box<T>(name: 'x')` |
| `emit()` after await | `if (isClosed) return;` first |
| `cv.cvtColor()` | `cv.cvtColorAsync()` |
| `result!.score` | `result?.score ?? 0` |
| `getIt<T>()` in build | Constructor injection |
