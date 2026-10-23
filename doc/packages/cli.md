# `axle_cli`

## What it is

The `axle` command-line compiler. It reads `axle.yaml`, scans Dart source with
`package:analyzer`, resolves annotation `Type` literals and DTO fields, and
writes the four artifacts every adapter serves. It depends on `axle_core` for
the document model and annotations — never on an adapter.

## Install

As a dev dependency so `dart run` can resolve it:

```yaml
dev_dependencies:
  axle_cli: ^0.1.0
```

Invoke locally:

```sh
dart run axle_cli:axle init
dart run axle_cli:axle gen
dart run axle_cli:axle gen --check
```

Or activate globally:

```sh
dart pub global activate axle_cli   # once published
axle init
axle gen
```

## API

### `axle init`

```
axle init [--project <dir>] [--force]
```

- Reads `pubspec.yaml` once to seed `info.title` and `info.version`.
- Writes `axle.yaml`.
- Never edits `pubspec.yaml` or `server.dart`.
- Refuses to overwrite without `--force`.
- Prints adapter-neutral setup guidance; no framework is assumed.
- There are no `--title`, `--version`, `--docs-path`, or `--spec-path` flags —
  edit the generated YAML instead.

### `axle gen`

```
axle gen [--project <dir>] [--config axle.yaml] [--check] [--verbose]
```

- Reads only `axle.yaml` and Dart source — never `pubspec.yaml`.
- Discovers top-level `@ApiRoute` handlers in the configured `scan` paths.
- Infers DTO schemas from referenced classes: nested classes, enums,
  `List`/`Set`, `Map<String, T>`, nullability, `DateTime`, `Uri`, `Duration`,
  `BigInt`, and typed-data bytes.
- Prints warnings to stderr; exit codes follow sysexits (usage `64`, data
  `65`, software `70`, config `78`).
- `--check` fails when any artifact is stale — use it in CI instead of
  regenerating.

## Examples

Minimal `axle.yaml`:

```yaml
openapi: 3.1.0
info:
  title: Todo API
  version: 0.1.0
generate:
  scan:
    - lib
  output:
    json: openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

One generation run:

```sh
dart run axle_cli:axle gen
```

```
Generated 3 paths and 5 schemas.
  openapi.json
  openapi.yaml
  assets/swagger-ui (2 assets)
  lib/src/generated/openapi.g.dart
```

The YAML artifact is derived by replacing the JSON extension with `.yaml` —
there is no separate YAML setting, so the two cannot drift. The Dart artifact
is a `const String axleOpenApiJson`: format-stable, importable, no runtime
file I/O. See the [axle.yaml reference](/reference/axle-yaml) for every rule.

## Boundaries

- No adapter or framework imports.
- No route binding, validation, or auth — it emits a contract, not behavior.
- One spec per package; no build_runner mode.
- Unsupported type shapes (generics, records, function types, sealed
  hierarchies) are errors, not guesses — see
  [Annotations & DTO Mapping](/reference/annotations).
