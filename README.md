# axle

OpenAPI 3.1 documentation for Dart servers, with adapters for [Relic](https://pub.dev/packages/relic) and [Shelf](https://pub.dev/packages/shelf).

axle is a small CLI plus a thin runtime. Annotate top-level handlers and DTOs, run the
generator, and serve the result:

- `build/openapi.json` for client generators and tooling.
- `build/openapi.yaml` as the YAML equivalent of the same document.
- `assets/swagger-ui/` for self-hosted Swagger UI.
- `lib/src/generated/openapi.g.dart` as a `const` string for AOT-safe serving.
- `GET /openapi.json` and `GET /docs` through an adapter.

The generator uses `package:analyzer`, so the spec is built from your Dart source
without `dart:mirrors` or a runtime registry.

## Packages

| Package | Purpose |
| --- | --- |
| `axle_core` | Annotations, OpenAPI 3.1 document model, `AxleDocs`, and Swagger UI HTML. No framework dependencies. |
| `axle_cli` | `axle init` and `axle gen`, analyzer-based source scanning, JSON/YAML/Dart artifacts, and self-hosted Swagger UI assets. |
| `axle_relic` | Relic adapter for `mountAxleDocs(...)` and standalone handlers. Re-exports core for Relic apps. |
| `axle_shelf` | Shelf adapter with composable handlers and local-asset support. |
| `axle_serverpod` | Serverpod adapter for web-server routes. Serving only; RPC endpoints are out of scope. |

## Quick start

Add the packages to a Relic project:

```yaml
dependencies:
  axle_relic: ^0.1.0
  relic: ^2.0.0-rc.2

dev_dependencies:
  axle_cli: ^0.1.0
```

`axle_relic` re-exports `axle_core`'s annotations and document model, so Relic
apps only need `axle_relic` plus the CLI. `axle_core` remains a standalone
dependency for other framework adapters.

Relic 2.0.0 is currently a release candidate. Pin `^2.0.0-rc.2` until the stable
2.x release is available, then update to `^2.0.0`.

> The packages are being prepared for their first publication. Until then, use
> `path:` dependencies (or the workspace in this repository) instead of version
> constraints.

Create the project configuration:

```sh
dart run axle_cli:axle init
```

`init` seeds `axle.yaml` from `pubspec.yaml`. After that, `axle.yaml` is the
source of truth for global API identity and generator paths; `gen` never reads
`pubspec.yaml`.

```yaml
openapi: 3.1.0
info:
  title: Todo API
  version: 0.1.0
  description: A Relic Todo API.
generate:
  scan:
    - lib
  output:
    json: build/openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

There is no `servers`, `docs`, `swagger_ui_url`, `tags`, or `security` block.
The runtime framework owns the address; tags stay on `@ApiRoute`; security is not
part of the contract yet.

`generate.output.json` is the spec path setting. The YAML file is derived by
replacing `.json` with `.yaml`, so the two artifacts cannot drift in config.
`generate.output.ui` is the directory where `axle gen` writes the self-hosted
Swagger UI assets; it defaults to `assets/swagger-ui` when omitted.

Annotate a top-level handler and its DTOs:

```dart
import 'package:axle_relic/axle_relic.dart';

@ApiSchema(description: 'A user returned by the API.')
class UserDto {
  final int id;
  final String name;
  const UserDto({required this.id, required this.name});
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  summary: 'Get a user',
  tags: ['Users'],
  pathParams: [ApiPathParam('id', type: int)],
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse.notFound(),
  ],
)
Future<Result> getUser(Request request) async { ... }
```

Generate the artifacts:

```sh
dart run axle_cli:axle gen
```

Mount the docs and spec:

```dart
import 'package:axle_relic/axle_relic.dart';
import 'package:relic/relic.dart';
import 'package:your_package/src/generated/openapi.g.dart';

final app = RelicApp();
app.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
await app.serve();
```

A complete runnable example is in
[`packages/axle_relic/example`](packages/axle_relic/example).

For Shelf, depend on `axle_shelf` and `shelf`, then mount the docs handler:

```dart
import 'package:axle_shelf/axle_shelf.dart';

final handler = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

See [`packages/axle_shelf`](packages/axle_shelf) for composition and local-asset
examples, including a complete runnable Todo API in
[`packages/axle_shelf/example`](packages/axle_shelf/example).

## CLI

```sh
dart run axle_cli:axle init [--project <dir>] [--force]
dart run axle_cli:axle gen [--project <dir>] [--config axle.yaml]
dart run axle_cli:axle gen --check
```

`init` writes `axle.yaml` and prints the setup steps. It does not edit your
`pubspec.yaml` or `server.dart`. `gen --check` fails when the generated files are
out of date, which is useful in CI.

## What is generated

- `openapi.json`, `openapi.yaml`, the Swagger UI asset directory, and the Dart
  constant from one generation run.
- Component schemas from referenced DTO classes, including nested classes, enums,
  `List`/`Set`, `Map<String, T>`, nullability, `DateTime`, `Uri`, `Duration`,
  `BigInt`, and `Uint8List`/`ByteData`.
- `@JsonKey(name: ...)` and `@ApiProperty(name: ...)` property names.
- Path, query, and header parameters, JSON request bodies, and responses.
- Deterministic path and schema ordering for clean diffs.

## Limitations

- Handlers must be top-level functions. Inline closures cannot carry annotations.
- Annotations describe the API; they do not bind requests, validate input, or
  serialize responses. Use your server framework for that.
- Wildcard routes (`*`, `/**`) cannot be represented in OpenAPI. Add
  `ignore: true` to their annotation.
- Relic 2.0.0-rc.2, Shelf, and Serverpod 4.x are the current adapter targets.
  The Dart Frog adapter is not included yet.
- Global `json_serializable` field renaming is not read yet. Use `@JsonKey` or
  `@ApiProperty` for custom names.

## Adapters

The shared adapter contract is [`AxleDocs`](docs/adapter-authoring.md). Adapters
serve the generated spec and UI; they do not bind routes or serialize responses.
Use `axle_relic`, `axle_shelf`, or `axle_serverpod` as the reference
implementations.

`axle gen` writes Swagger UI 5.34.0 into `generate.output.ui`. Pass that
directory to an adapter to self-host the UI; no extra asset package is required.
The CDN URL remains available as an opt-in fallback and is pinned with SRI
hashes.

## Development

See [`docs/axle-roadmap.md`](docs/axle-roadmap.md) for the full design, scope,
current status, and roadmap.

```sh
dart pub get
dart run melos run check   # analyze + test + format + spec freshness
```

Useful individual scripts:

```sh
dart run melos run analyze
dart run melos run test
dart run melos run format
dart run melos run gen-check
dart run melos run coverage   # writes coverage/lcov.info for Codecov
```
