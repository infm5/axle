# axle_shelf

Shelf integration for axle.

## Install

```yaml
dependencies:
  axle_shelf: ^0.3.0
  shelf: ^1.4.3

dev_dependencies:
  axle_cli: ^0.3.0
```

Generate the spec before the first run:

```sh
dart run axle_cli:axle init
dart run axle_cli:axle gen
```

`axle_shelf` serves a generated OpenAPI document and Swagger UI from Shelf. It
re-exports `axle_core` for one-import apps. It does not bind routes, validate
requests, serialize responses, or enforce auth.

```dart
import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';

final handler = axleDocsHandler(spec: axleOpenApiJson);

final pipeline = const Pipeline()
    .addHandler(handler);
```

The default routes are `GET /openapi.json` and `GET /docs`. Local UI assets are
served at `GET /docs-assets/*` when `swaggerUiDirectory` is set. Use `specPath`,
`docsPath`, `title`, and `noCache` to customize them. The handler returns
`404` for unrelated paths, so it composes with a router or a `Cascade`.

For custom routing, use the standalone handlers with an `AxleDocs` payload:

```dart
final docs = AxleDocs(spec: axleOpenApiJson);

router
  ..get(docs.specPath, openApiJsonHandler(docs))
  ..get(docs.docsPath, swaggerUiHandler(docs));
```

The default Swagger UI URL is pinned to Swagger UI 5.34.0 and uses SRI hashes.
For offline deployments, let `axle gen` create `assets/swagger-ui` and point the
adapter at it:

```dart
final handler = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

The handler serves the generated UI assets at `/docs-assets` by default. Use
`swaggerUiPath` to change the prefix. Relative directory paths are resolved from
the process working directory; use an absolute path in deployments if needed.
The standalone `swaggerUiAssetsHandler(directory)` is available when you need to
compose the asset handler yourself.

See [`example/`](example/) for a complete Shelf Todo API with a router,
generated spec, and local Swagger UI assets. It also demonstrates API key
security, response headers, cookies, content negotiation, constraints, `oneOf`
schemas, and multipart uploads. See the
[adapter authoring guide](https://github.com/infm5/axle/blob/master/docs/adapter-authoring.md)
for the framework-neutral contract.

The adapter serves the generated OpenAPI document verbatim, including
`securitySchemes`, `security`, response headers, cookies, and media types. It
does not enforce security; the example handlers show application-owned checks.
