# axle_relic

Relic integration for axle.

`axle_relic` re-exports `axle_core`, so Relic apps get the annotations, document
model, and docs helpers from one import.

```dart
import 'package:axle_relic/axle_relic.dart';
import 'package:relic/relic.dart';
import 'package:your_package/src/generated/openapi.g.dart';

final app = RelicApp();
app.mountAxleDocs(spec: axleOpenApiJson);
```

`mountAxleDocs` registers `GET /openapi.json` and `GET /docs` by default. Both the
spec and UI responses use `Cache-Control: no-store` unless `noCache: false` is
passed. The Swagger UI title comes from the spec's `info.title` unless you pass
`title:` explicitly. Path normalization, title resolution, and cache policy come
from the shared `AxleDocs` contract in `axle_core`.

The default Swagger UI URL is pinned to Swagger UI 5.34.0 and uses SRI hashes.
Pass `swaggerUiUrl` to use a self-hosted location.

For custom routing, use the standalone handlers:

```dart
app
  ..get('/openapi.json', openApiJsonHandler(axleOpenApiJson))
  ..get('/docs', swaggerUiHandler(specPath: '/openapi.json'));
```

For offline deployments, let `axle gen` create `assets/swagger-ui` and point
the adapter at it:

```dart
app.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

The adapter mounts the generated UI assets at `/docs-assets` by default. Use
`swaggerUiPath` to change the prefix. Relative directory paths are resolved from
the process working directory; use an absolute path in deployments if needed.
The standalone `mountSwaggerUiAssets(directory)` method is available for custom
composition.

See [`example/`](example/) for a complete Relic Todo API and
[`docs/adapter-authoring.md`](https://github.com/infmslabs/axle/blob/main/docs/adapter-authoring.md) for the shared
adapter contract.

The package targets Relic 2.0.0-rc.2 and will move to the stable Relic 2.x line
once it is published.
