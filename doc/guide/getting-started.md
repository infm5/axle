# Getting Started

This guide wires axle into a project end to end using the Relic adapter. Shelf
and Serverpod use the same flow with their own dependency and mount call — see
[axle_shelf](/packages/shelf) and [axle_serverpod](/packages/serverpod).

## Prerequisites

- Dart SDK (the workspace requires `>=3.12.2 <4.0.0`).
- A Dart server project using `relic`, `shelf`, or Serverpod 4.x.

## 1. Add the dependencies

For a Relic project:

```yaml
dependencies:
  axle_relic: ^0.1.0
  relic: ^2.0.0-rc.2

dev_dependencies:
  axle_cli: ^0.1.0
```

`axle_relic` re-exports `axle_core`, so Relic apps only need `axle_relic` plus
the CLI. For Shelf, depend on `axle_shelf` and `shelf` instead. For Serverpod
4.x, use the web-server adapter:

```yaml
dependencies:
  axle_serverpod: ^0.1.0
  serverpod: ^4.0.0

dev_dependencies:
  axle_cli: ^0.1.0
```

`axle_serverpod` also re-exports `axle_core`. Its docs routes run on
`pod.webServer`, not the API server.

::: warning
Relic 2.0.0 is currently a release candidate. Pin `^2.0.0-rc.2` until the
stable 2.x release is available.
:::

## 2. Create `axle.yaml`

```sh
dart run axle_cli:axle init
```

`init` seeds `axle.yaml` from `pubspec.yaml`. After that, `axle.yaml` is the
source of truth for global API identity and generator paths — `gen` never reads
`pubspec.yaml` again.

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
    json: openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

There is no `servers`, `docs`, `swagger_ui_url`, `tags`, or `security` block.
The framework owns the runtime address, tags stay on `@ApiRoute`, and security
is not part of the contract yet. The YAML artifact path is derived from the
JSON path, so the two can never drift in configuration. See the
[axle.yaml reference](/reference/axle-yaml) for the full rules.

## 3. Annotate a handler and its DTOs

Annotations live next to top-level handler functions and DTO classes:

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

Notes:

- Handlers must be **top-level functions**; closures cannot carry metadata.
- Parameters carry a Dart `Type` literal (e.g. `type: int`), never a nullable
  type literal — nullability is expressed per-field or per-response.
- Schemas are inferred from DTO classes referenced by `ApiBody` / `ApiResponse`.
  `@ApiSchema` is optional and only force-includes unreferenced models or
  overrides metadata.

Serverpod handlers are `handleCall` methods on `Route` subclasses, so annotate a
top-level function and delegate from the route. Keep the annotation path and
the `addRoute` path in one constant:

```dart
const greetingPath = '/greeting';

@ApiRoute(
  method: ApiMethod.get,
  path: greetingPath,
  responses: [ApiResponse.ok(Greeting)],
)
Future<Response> greeting(Session session, Request request) async {
  // ...
}

class GreetingRoute extends Route {
  GreetingRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      greeting(session, request);
}
```

See [Annotations & DTO Mapping](/reference/annotations) for the full surface.

## 4. Generate the artifacts

```sh
dart run axle_cli:axle gen
```

One run writes four things:

| Artifact | Default | Used for |
| --- | --- | --- |
| `openapi.json` | `generate.output.json` | Client generators, tooling, diffs |
| `openapi.yaml` | JSON path with `.yaml` | YAML-based tooling |
| `assets/swagger-ui/` | `generate.output.ui` | Self-hosted Swagger UI |
| `openapi.g.dart` | `generate.output.dart` | `const String axleOpenApiJson` for AOT-safe serving |

In CI, verify freshness instead of regenerating:

```sh
dart run axle_cli:axle gen --check
```

`--check` exits non-zero when any artifact is stale.

## 5. Mount the docs

Relic:

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

Shelf:

```dart
import 'package:axle_shelf/axle_shelf.dart';

final handler = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

Serverpod:

```dart
import 'package:axle_serverpod/axle_serverpod.dart';
import 'package:your_package/src/generated/openapi.g.dart';

pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
await pod.start();
```

Omit `swaggerUiDirectory` to use the pinned CDN-backed UI instead of local assets.

## 6. Run and verify

```sh
dart run bin/server.dart
```

Then open:

- `http://localhost:8080/docs` — Swagger UI
- `http://localhost:8080/openapi.json` — the generated spec

For Serverpod, use the **web server** port (`8082` in the example), not the
API server port (`8090`). The example mounts the UI at `/swagger`:

- `http://localhost:8082/swagger`
- `http://localhost:8082/openapi.json`

`serverpod start` lists API Endpoint methods in its terminal UI and Insights;
web-server routes such as `/greeting` are intentionally not in that list.

## Complete examples

Runnable examples for all three frameworks live in the repository:

- [`packages/axle_relic/example`](https://github.com/infm5/axle/tree/master/packages/axle_relic/example)
- [`packages/axle_shelf/example`](https://github.com/infm5/axle/tree/master/packages/axle_shelf/example)
- [`packages/axle_serverpod/example`](https://github.com/infm5/axle/tree/master/packages/axle_serverpod/example)

See [Examples](/guide/examples) for a walkthrough of all three.
