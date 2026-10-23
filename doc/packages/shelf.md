# `axle_shelf` — Shelf adapter deep dive

## What it is

The Shelf runtime adapter. It serves the generated spec and Swagger UI through
a composable `Handler` built on the same `AxleDocs` contract as `axle_relic`.
It re-exports `axle_core` for one-import apps, and — like every adapter — it
does not bind routes, validate requests, serialize responses, or enforce auth.

## Install

```yaml
dependencies:
  axle_shelf: ^0.1.0
  shelf: ^1.4.0

dev_dependencies:
  axle_cli: ^0.1.0
```

```dart
import 'package:axle_shelf/axle_shelf.dart';
```

## API

### `axleDocsHandler` — the composable handler

Returns a `Handler` responding to `GET` at `specPath` and `docsPath`, plus the
local assets when configured. It returns `404` for every other path and for
non-`GET` requests, so it drops cleanly into a router or a `Cascade`:

```dart
import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:your_package/src/generated/openapi.g.dart';

final docsHandler = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);

final api = Router()..get('/notes', listNotes);
final handler = Cascade()
    .add(api.call)
    .add(docsHandler)
    .handler;
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

Request paths are normalized before matching, so `docs` and `/docs` behave
identically. `swaggerUiPath` must not be `/`, the spec path, or the docs path.

### Standalone handlers

For custom routing, build on an `AxleDocs` payload directly:

```dart
final docs = AxleDocs(spec: axleOpenApiJson);

router
  ..get(docs.specPath, openApiJsonHandler(docs))
  ..get(docs.docsPath, swaggerUiHandler(docs));
```

- `openApiJsonHandler(docs)` — serves `docs.specJson` as `application/json`
  with `docs.headers`.
- `swaggerUiHandler(docs)` — serves `docs.uiHtml` as
  `text/html; charset=utf-8` with `docs.headers`.
- `swaggerUiAssetsHandler(directory, {pathPrefix, noCache})` — serves the
  `generate.output.ui` directory under the prefix via `shelf_static`. Only
  `GET` requests under the prefix are served; path traversal and symlinks
  escaping the directory are rejected by `shelf_static`.

## Examples

CDN-backed UI inside a pipeline:

```dart
final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addHandler(axleDocsHandler(spec: axleOpenApiJson));
```

Self-hosted UI with a custom asset prefix:

```dart
final handler = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
  swaggerUiPath: '/static/docs',
);
```

The complete runnable Todo API is at
[`packages/axle_shelf/example`](https://github.com/infm5/axle/tree/master/packages/axle_shelf/example)
— annotated Shelf handlers, a Shelf router for application routes, generated
specs, generated `openapi.g.dart`, and local Swagger UI assets. If you only
need the CDN-backed UI, omit `swaggerUiDirectory`.

## Relic vs Shelf at a Glance

Both adapters expose the same parameter names, defaults, and semantics because
both delegate to `AxleDocs`. The only differences are framework-shaped:

| Concern | `axle_relic` | `axle_shelf` |
| --- | --- | --- |
| Mounting | `app.mountAxleDocs(...)` extension on `RelicApp` | `axleDocsHandler(...)` returns a composable `Handler` |
| Standalone spec | `openApiJsonHandler(specString)` | `openApiJsonHandler(axleDocs)` |
| Standalone UI | `swaggerUiHandler(...)` with individual args | `swaggerUiHandler(axleDocs)` |
| Assets | `mountSwaggerUiAssets(dir)` registers per-file routes | `swaggerUiAssetsHandler(dir)` returns a `shelf_static` handler |
| Unknown routes | Relic router 404 | Handler returns `404`, composes with `Cascade` |

A third adapter for any framework follows this same shape — see
[Building an Adapter](/adapters/building-an-adapter).

## Boundaries

- Serves the spec **verbatim**; never transforms it.
- Non-`GET` requests and unrelated paths get `404`, never method errors or redirects.
- Relative directory paths resolve from the process working directory — use an
  absolute path in deployments if needed.
