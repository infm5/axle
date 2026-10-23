# `axle.yaml` Reference

`axle.yaml` owns only global contract identity and compiler settings. It is
created by `axle init` and is afterwards the single source of truth — `gen`
reads only this file and Dart source, never `pubspec.yaml`.

## Full example

```yaml
openapi: 3.1.0

info:
  title: Todo API
  version: 0.1.0
  description: A Relic Todo API.
  contact:
    name: Example
    email: dev@example.com
  license:
    name: MIT

generate:
  scan:
    - lib
  output:
    json: openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

## Fields

| Field | Required | Meaning |
| --- | --- | --- |
| `openapi` | yes | Must be a supported `3.1.x` version |
| `info` | yes | Maps to the OpenAPI Info Object |
| `info.title` | yes | API title; also seeds the Swagger UI title |
| `info.version` | yes | API version |
| `info.description` | no | API description |
| `info.contact` | no | `name`, `url`, `email` |
| `info.license` | no | `name`, `identifier`, `url` |
| `generate.scan` | yes | One or more directories or files to scan |
| `generate.output.json` | yes | Spec path, relative to the project root (or absolute inside it) |
| `generate.output.ui` | no | Swagger UI asset directory (default: `assets/swagger-ui`) |
| `generate.output.dart` | yes | Dart artifact path for `const String axleOpenApiJson` |

The YAML artifact has **no setting**: `openapi.yaml` is derived by replacing
the JSON extension with `.yaml`, so JSON and YAML can never drift in config.

## Rules

- `init` reads `pubspec.yaml` once to seed `info.title` and `info.version`.
- After `init`, `axle.yaml` is authoritative; `gen` never reads `pubspec.yaml`.
- Unknown keys are errors.
- `scan` paths and output paths must stay inside the project root.
- `generate.scan` supports one or more directories or files.
- `info` maps to the OpenAPI Info Object; `openapi` must be supported 3.1.x.

## Deliberately absent

| Key | Why |
| --- | --- |
| `servers` | The framework owns host/port; duplicating it creates drift. Swagger UI uses the current origin. |
| `docs` | Docs routing and UI title are runtime adapter concerns. |
| `swagger_ui_url` | The default lives in `axle_core` (pinned 5.34.0 + SRI); local assets come from `generate.output.ui`. |
| `tags` | Tags are operation-local on `@ApiRoute`. |
| `security` | Deferred — axle cannot enforce auth, so it must not declare it. |
