# axle_serverpod

Serverpod integration for axle. Serves a generated OpenAPI document and
Swagger UI from Serverpod's web server.

## Install

```yaml
dependencies:
  axle_serverpod: ^0.1.0
  serverpod: ^4.0.0

dev_dependencies:
  axle_cli: ^0.1.0
```

Generate the spec before the first run:

```sh
dart run axle_cli:axle init
dart run axle_cli:axle gen
```

`axle_serverpod` re-exports `axle_core`, so annotations, the document model,
and docs helpers come from one import.

## Use

Register the docs routes before `pod.start()`:

```dart
import 'package:axle_serverpod/axle_serverpod.dart';
import 'package:your_package/src/generated/openapi.g.dart';

pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

The defaults serve Swagger UI at `/docs`, the OpenAPI document at
`/openapi.json`, and generated UI assets at `/docs-assets`.

A runnable Docker-free example lives in
[`example/`](https://github.com/infm5/axle/tree/master/packages/axle_serverpod/example).

These routes run on the **web server** port, not the API server port. Open the
port configured for `pod.webServer` when you check the docs locally.

## API

### `mountAxleDocs` (extension on `WebServer`)

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

All paths are absolute, so the docs can be mounted anywhere:

```dart
pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  specPath: '/internal/api/openapi.json',
  docsPath: '/internal/api/reference',
  swaggerUiDirectory: 'assets/swagger-ui',
  swaggerUiPath: '/internal/api/assets',
);
```

`swaggerUiPath` must not be `/`, the spec path, or the docs path. A local assets
directory must exist and contain files; the mount fails at startup otherwise.
Calling `mountAxleDocs` multiple times with distinct paths creates independent
docs surfaces.

Returns the configured `AxleDocs`. Path normalization, title resolution, and
cache policy come from the shared `AxleDocs` contract in `axle_core`; the
adapter only wires them to Serverpod routes. `swaggerUiPath` must not be `/`,
the spec path, or the docs path.

When `swaggerUiDirectory` is omitted, the UI loads the pinned CDN distribution
(Swagger UI 5.34.0 with SRI hashes). When it is set, assets are served by
Serverpod's `StaticRoute.directory`, so ETag, conditional, and range requests
come from the framework. The directory must exist — run `axle gen` first.

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
  `StaticRoute.directory` at the prefix.
- `openApiJsonResponse(docs)` / `swaggerUiResponse(docs)` — build the Relic
  `Response` objects directly for use in your own `Route`.

## Documenting Serverpod REST routes

Serverpod exposes two HTTP surfaces, and only one is REST:

- **API-server endpoints** (`Endpoint` subclasses) speak the Serverpod
  protocol over POST. They have no HTTP method or status-code semantics, so
  they are not described by OpenAPI.
- **Web-server routes** (`Route` subclasses added with
  `pod.webServer.addRoute`) are ordinary HTTP: methods, `:param` segments,
  wildcards, and status codes. This is what axle documents.

`axle gen` discovers annotations on top-level functions, while Serverpod REST
handlers are `handleCall` methods on `Route` subclasses. Annotate a top-level
function and delegate from the route:

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

## Boundaries

- Serves the spec **verbatim** as `application/json`; never transforms it.
- Serves the UI as `text/html`; generated assets come from the framework's
  static handler.
- Does not bind application routes, validate requests, serialize responses, or
  enforce auth. Protect the docs routes with Serverpod middleware if needed.
- Does not document API-server `Endpoint` methods.
- Targets Serverpod 4.x (`^4.0.0`), which uses Relic 2.x. Serverpod 3.x uses
  Relic 1.x and is not supported.
