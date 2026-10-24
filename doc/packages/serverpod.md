# `axle_serverpod` — Serverpod adapter deep dive

## What it is

The Serverpod runtime adapter. It mounts the generated spec and Swagger UI on a
Serverpod `WebServer` and maps the shared `AxleDocs` values to Relic responses,
headers, and static-file routes. It contains no generation logic, no route
discovery, and no auth — and it re-exports `axle_core`, so Serverpod apps get
annotations, the document model, and docs helpers from one import.

Serverpod has two HTTP surfaces. API-server endpoints (`Endpoint` subclasses)
speak the Serverpod protocol over POST and are not REST; the adapter does not
describe them. Web-server routes (`Route` subclasses) are ordinary HTTP and are
what axle documents.

::: tip
`serverpod start` and Insights list `Endpoint` methods. They do not list
web-server `Route`s, so docs mounted with `mountAxleDocs` will not appear in
that explorer. Open the configured docs path on the **web server** port instead.
:::

## Install

```yaml
dependencies:
  axle_serverpod: ^0.2.0
  serverpod: ^4.0.0

dev_dependencies:
  axle_cli: ^0.2.0
```

```dart
import 'package:axle_serverpod/axle_serverpod.dart';
```

::: warning
The adapter targets Serverpod 4.x. Serverpod 3.x depends on Relic 1.x and is
not supported.
:::

## API

### `mountAxleDocs` (extension on `WebServer`)

The standard way to serve docs — registers `GET` routes for the spec, the UI,
and (optionally) the local asset files:

```dart
import 'package:axle_serverpod/axle_serverpod.dart';
import 'package:your_package/src/generated/openapi.g.dart';

pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
await pod.start();
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

The method returns the configured `AxleDocs`. Path normalization, title
resolution, and cache policy all come from the shared `AxleDocs` contract in
`axle_core` — the adapter only wires them to Serverpod routes. `swaggerUiPath`
must not be `/`, the spec path, or the docs path.

These routes are served by the **web server**, not the API server. Open the
`pod.webServer` port when checking the docs locally.

### Mounting under any route

All three paths are absolute web-server routes. Put the docs under a prefix, a
subdomain, or an internal-only path by passing all three:

```dart
pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  specPath: '/internal/api/openapi.json',
  docsPath: '/internal/api/reference',
  swaggerUiDirectory: 'assets/swagger-ui',
  swaggerUiPath: '/internal/api/assets',
);
```

The UI HTML points at the spec path you configured, and local assets are served
under the prefix you configured, so no relative-path assumptions break. The
`swaggerUiPath` must not be `/`, the spec path, or the docs path. The assets
directory must exist and contain files — the mount fails at startup otherwise,
instead of serving a UI with broken assets.

Calling `mountAxleDocs` more than once with distinct paths gives you independent
surfaces (for example, a public `/docs` and an internal `/internal/docs`).
Reusing a path is a Serverpod route collision.

::: tip
Local assets use Serverpod's `StaticRoute.directory`, so ETag, conditional, and
range requests are handled by the framework. When `noCache` is `true`, the
adapter passes `StaticRoute.noStore()` as the cache policy.
:::

### Manual routes

For custom registration, compose the pieces yourself:

```dart
final docs = AxleDocs(spec: axleOpenApiJson);

pod.webServer
  ..addRoute(AxleOpenApiRoute(docs), docs.specPath)
  ..addRoute(AxleDocsRoute(docs), docs.docsPath)
  ..mountSwaggerUiAssets('assets/swagger-ui');
```

- `AxleDocsRoute(docs)` — responds to `GET` with the Swagger UI page.
- `AxleOpenApiRoute(docs)` — responds to `GET` with the JSON document.
- `mountSwaggerUiAssets(directory, {pathPrefix, noCache})` — mounts a
  `StaticRoute.directory`; the directory must exist.
- `openApiJsonResponse(docs)` / `swaggerUiResponse(docs)` — build the Relic
  `Response` objects for your own `Route`.

Relative directory paths resolve from the process working directory — use an
absolute path in deployments if needed.

## Documenting Serverpod REST routes

`axle gen` discovers annotations on top-level functions. Serverpod REST
handlers are `handleCall` methods on `Route` subclasses, so annotate a
top-level function and delegate from the route:

```dart
const getTodoPath = '/todos/:id';

@ApiRoute(
  method: ApiMethod.get,
  path: getTodoPath,
  pathParams: [ApiPathParam('id', type: int)],
  responses: [ApiResponse.ok(TodoDto)],
)
Future<Response> getTodo(Session session, Request request) async {
  // ...
}

class TodoRoute extends Route {
  TodoRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      getTodo(session, request);
}

pod.webServer.addRoute(TodoRoute(), getTodoPath);
```

Derive the annotation path and the `addRoute` path from one constant. The
generator cannot see the router, so two independent path strings can drift.

## Examples

The complete Docker-free example is at
[`packages/axle_serverpod/example`](https://github.com/infm5/axle/tree/master/packages/axle_serverpod/example)
— an annotated `/greeting` route backed by the generated Serverpod
`GreetingEndpoint.hello`, with the `Greeting` protocol model mapped into the
OpenAPI schema and a mounted docs surface on the web server port.

CDN-backed UI (no local assets):

```dart
pod.webServer.mountAxleDocs(spec: axleOpenApiJson);
```

Self-hosted UI with custom paths:

```dart
pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  specPath: '/api-spec.json',
  docsPath: '/reference',
  title: 'Todo API Docs',
  swaggerUiDirectory: 'assets/swagger-ui',
  swaggerUiPath: '/reference-assets',
  noCache: false,
);
```

## Boundaries

- Serves the spec **verbatim** as `application/json`; never transforms it.
- Serves the UI as `text/html`; assets come from the framework's static handler.
- Does not bind application routes, validate requests, serialize responses, or
  enforce auth. Protect the docs routes with Serverpod middleware if needed.
- Does not document API-server `Endpoint` methods or the Serverpod protocol.
- Targets Serverpod 4.x; Serverpod 3.x is not supported.

## Other adapters

- [axle_relic](/packages/relic) — Relic `RelicApp` routes.
- [axle_shelf](/packages/shelf) — composable Shelf handlers.
- [Adapter comparison](/packages/#adapter-comparison) — mounting and asset
  differences at a glance.
