# `axle_relic` — Relic adapter deep dive

## What it is

The Relic runtime adapter. It mounts the generated spec and Swagger UI on a
`RelicApp` and maps the shared `AxleDocs` values to Relic responses and
headers. It contains no generation logic, no route discovery, and no auth
enforcement — and it re-exports `axle_core`, so Relic apps get annotations, the
document model, and docs helpers from one import.

## Install

```yaml
dependencies:
  axle_relic: ^0.2.0
  relic: ^2.0.0-rc.2

dev_dependencies:
  axle_cli: ^0.2.0
```

```dart
import 'package:axle_relic/axle_relic.dart';
```

::: warning
Relic 2.0.0 is currently a release candidate. Pin `^2.0.0-rc.2` until stable 2.x.
:::

## API

### `mountAxleDocs` (extension on `RelicApp`)

The standard way to serve docs — registers `GET` routes for the spec, the UI,
and (optionally) the local asset files:

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

| Parameter | Default | Meaning |
| --- | --- | --- |
| `spec` (required) | — | The generated JSON string (`axleOpenApiJson`) |
| `specPath` | `'/openapi.json'` | Where the spec is served |
| `docsPath` | `'/docs'` | Where Swagger UI is served |
| `title` | spec's `info.title` | Browser title; falls back to `API Docs` |
| `swaggerUiUrl` | pinned CDN (5.34.0 + SRI) | Asset base URL when no local directory is given |
| `swaggerUiDirectory` | `null` | `generate.output.ui` dir; enables local asset serving |
| `swaggerUiPath` | `'/docs-assets'` | URL prefix for the local assets |
| `noCache` | `true` | Sends `Cache-Control: no-store` on spec, UI, and assets |

Path normalization, title resolution, and cache policy all come from the
shared `AxleDocs` contract in `axle_core` — the adapter only wires them to
Relic routes. `swaggerUiPath` must not be `/`, the spec path, or the docs path.

### Standalone handlers

For custom routing, compose the pieces yourself:

```dart
app
  ..get('/openapi.json', openApiJsonHandler(axleOpenApiJson))
  ..get('/docs', swaggerUiHandler(specPath: '/openapi.json'));
```

- `openApiJsonHandler(spec, {noCache})` — serves the spec as JSON. Builds its
  own `AxleDocs` internally, so default paths and cache policy still apply.
- `swaggerUiHandler({specPath, title, swaggerUiUrl, noCache})` — serves the UI
  shell pointing at `specPath`.
- `mountSwaggerUiAssets(directory, {pathPrefix, noCache})` — registers one
  `GET` route per asset file under the prefix. The directory must exist and be
  non-empty (i.e. run `axle gen` first); files outside the directory can never
  match, and symlinks escaping it are skipped.

Relative directory paths resolve from the process working directory — use an
absolute path in deployments if needed.

## Examples

CDN-backed UI (no local assets):

```dart
app.mountAxleDocs(spec: axleOpenApiJson);
```

Self-hosted UI with custom paths:

```dart
app.mountAxleDocs(
  spec: axleOpenApiJson,
  specPath: '/api-spec.json',
  docsPath: '/reference',
  title: 'Todo API Docs',
  swaggerUiDirectory: 'assets/swagger-ui',
  swaggerUiPath: '/reference-assets',
  noCache: false,
);
```

The complete runnable Todo API is at
[`packages/axle_relic/example`](https://github.com/infm5/axle/tree/master/packages/axle_relic/example)
— models, in-memory repository, annotated route modules, shared HTTP helpers,
generated specs, generated `openapi.g.dart`, and local Swagger UI assets. It also
demonstrates an `apiKey` scheme with real `X-API-Key` checks, response headers,
cookie parameters, content negotiation, query/path constraints, a `oneOf`
activity response, and a multipart upload with a binary file property.
`/health`, `/todos`, `/todos/stats`, `/todos/activity`, `/todos/import`,
`/openapi.json`, `/docs`, and `/docs-assets` were all verified against a live
server.

## Boundaries

- Serves the spec **verbatim** as `application/json`; never transforms it.
- Serves the UI as `text/html; charset=utf-8`.
- Does not bind application routes, validate requests, serialize responses, or
  enforce auth. It serves generated security metadata verbatim but never
  validates credentials. Protect the docs routes with your own middleware if
  needed.
- Targets Relic 2.0.0-rc.2; will move to stable Relic 2.x once published.

## Other adapters

- [axle_shelf](/packages/shelf) — composable Shelf handlers.
- [axle_serverpod](/packages/serverpod) — Serverpod web-server routes.
- [Adapter comparison](/packages/#adapter-comparison) — mounting and asset
  differences at a glance.
