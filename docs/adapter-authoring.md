# Building an axle adapter

An axle adapter is intentionally small. It serves the generated OpenAPI document
and Swagger UI through one web framework. It does not parse annotations, bind
application routes, validate requests, serialize responses, or enforce auth.

This mirrors Swaggo's split between `swag` (spec generation) and its framework
packages (runtime serving). Axle improves on that split by putting path, title,
cache, and HTML behavior in the shared `AxleDocs` contract.

## Dependency boundary

```text
application
  ├── axle_cli (dev dependency)
  ├── an adapter (axle_relic, axle_shelf, ...)
  │     └── axle_core
  └── framework
```

- `axle_core` is framework-agnostic and has no runtime dependencies.
- Adapters depend on `axle_core`; they may re-export it for convenience.
- The CLI depends on `axle_core` but never on an adapter.
- Adapter packages must not require changes to core or to the CLI.

## The contract

Create one `AxleDocs` per mounted docs surface:

```dart
final docs = AxleDocs(
  spec: axleOpenApiJson,
  specPath: '/openapi.json',
  docsPath: '/docs',
  title: null, // read info.title
  noCache: true,
);
```

`AxleDocs` owns the behavior that every adapter must otherwise duplicate:

- `specJson`: the exact generated JSON artifact.
- `specPath` and `docsPath`: normalized to a leading `/`.
- `title`: explicit title or the spec's `info.title`, falling back to `API Docs`.
- `uiHtml`: the Swagger UI HTML shell.
- `headers`: `cache-control: no-store` when caching is disabled.
- Empty and identical paths are rejected.

The adapter maps these values to its framework:

| Route | Body | Content type | Headers |
| --- | --- | --- | --- |
| `GET {specPath}` | `docs.specJson` | `application/json` | `docs.headers` |
| `GET {docsPath}` | `docs.uiHtml` | `text/html; charset=utf-8` | `docs.headers` |

The adapter should also expose standalone spec and UI handlers when its
framework supports composable handlers.

## Reference implementation

`axle_relic` and `axle_shelf` are the reference implementations. A minimal
adapter is roughly:

```dart
final docs = AxleDocs(spec: spec, specPath: specPath, docsPath: docsPath);

framework.get(docs.specPath, (request) {
  return framework.response(
    status: 200,
    contentType: 'application/json',
    headers: docs.headers,
    body: docs.specJson,
  );
});

framework.get(docs.docsPath, (request) {
  return framework.response(
    status: 200,
    contentType: 'text/html; charset=utf-8',
    headers: docs.headers,
    body: docs.uiHtml,
  );
});
```

Do not add a framework-specific request or response type to `axle_core`.

## Swagger UI assets

The default Swagger UI URL is pinned to Swagger UI 5.34.0 and includes SRI
hashes. It remains an opt-in fallback.

For offline or self-hosted deployments, `axle gen` writes the Swagger UI files
to `generate.output.ui` (default: `assets/swagger-ui`). Adapters should accept a
directory path and serve its files under a configurable prefix:

```dart
app.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

The core package does not own the asset files and adapters must not depend on
the CLI at runtime. Generated files are ordinary static assets, so a third-party
adapter can use its framework's file-serving primitive or a small file handler.
Reject path traversal and symlinks that escape the configured directory.

## Security

- The spec and UI routes are public by default. Applications must protect them
  with their own middleware if needed.
- The default UI uses a pinned CDN with SRI. Generated local assets avoid the
  CDN entirely.
- Do not inject untrusted content into the UI title or spec URL; `AxleDocs`
  escapes both.
- Prefer `Cache-Control: no-store` for docs and specs unless the application
  explicitly opts out.

## Adapter checklist

- [ ] Create `AxleDocs` and honor its normalized paths, title, and headers.
- [ ] Serve the exact spec bytes as `application/json`.
- [ ] Serve the UI as `text/html; charset=utf-8`.
- [ ] Return `404` for unrelated routes and non-GET requests.
- [ ] Integrate with the framework's routing/composition model.
- [ ] Expose standalone handlers where useful.
- [ ] Support local Swagger UI assets from `generate.output.ui`.
- [ ] Add tests for default/custom paths, title fallback, no-cache behavior,
      content types, and local assets.
- [ ] Document installation, mounting, and the framework version range.
- [ ] Keep the adapter version independent of the CLI version.
- [ ] Publish changelog and compatibility notes.

## Compatibility policy

Adapters should depend on a compatible `axle_core` range, for example:

```yaml
dependencies:
  axle_core: ^0.1.0
```

Core is the stable contract. Adapters must not expose CLI internals or require
users to match the CLI version.

Current Dart floors are intentionally split: core supports Dart 3.7+, Shelf
follows Shelf's floor, Relic follows Relic's floor, and the analyzer-based CLI
has the highest floor. Do not force every adapter to the CLI's SDK requirement.

## Not in scope

- Binding or generating application routes.
- Runtime request/response validation.
- Serialization.
- Authentication or authorization.
- Class/method endpoint discovery. The current generator documents top-level
  functions; broader endpoint shapes are a future core feature.
