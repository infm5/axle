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
  axle_cli: ^0.3.0
```

`axle_cli` needs a recent `analyzer`. It resolves next to `json_serializable` and
`dart_mappable_builder`, but not next to freezed 3.x; activate it globally there
(below).
Invoke locally:

```sh
dart run axle_cli:axle init
dart run axle_cli:axle gen
dart run axle_cli:axle gen --check
```

Or activate globally. This is required next to freezed 3.x, and it analyzes your
project with your project's own packages:

```sh
dart pub global activate axle_cli
axle init
axle gen
```

Run `dart pub global activate axle_cli` again after upgrading axle.

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
- Discovers `@ApiRoute` annotations in the configured `scan` paths: on
  top-level functions, and from 0.3.0 also on methods and top-level variables.
- Infers DTO schemas from referenced classes: nested classes, enums,
  `List`/`Set`, `Map<String, T>`, nullability, `DateTime`, `Uri`, `Duration`,
  `BigInt`, and typed-data bytes. From 0.3.0 it also handles generic classes,
  sealed classes, and the annotations of `json_serializable`, `freezed`, and
  `dart_mappable`.
- Emits security schemes/requirements, response headers, cookie parameters,
  multiple media types, multipart bodies, parameter constraints, and `oneOf`,
  `anyOf`, and `allOf` schemas. From 0.3.0 it also emits `default` and range
  responses, parameter `style` and `explode`, and named examples.
- Validates security references against `security.schemes` in `axle.yaml`.
- Reports every source problem in one run as `file:line:column: error: …`
  (before 0.3.0 it stopped at the first). Warnings print to stderr and do not
  change the exit code. Exit codes follow sysexits (usage `64`, data `65`,
  software `70`, config `78`).
- Reads generated parts (`*.freezed.dart`, `*.mapper.dart`), so run your code
  generator first. Files that `analysis_options.yaml` excludes are fine.
- `--check` fails when any artifact is stale — use it in CI instead of
  regenerating.

## Examples

Minimal `axle.yaml`:

```yaml
openapi: 3.1.0
info:
  title: Todo API
  version: 0.2.0
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
- No route binding, request validation, or auth enforcement — it emits a
  contract, not behavior.
- One spec per package; no build_runner mode.
- Unsupported type shapes (records, function types) are errors or documented
  omissions, not guesses. See [Annotations and DTO Mapping](/reference/annotations).
