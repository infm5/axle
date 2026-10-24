# axle_core

Framework-agnostic OpenAPI 3.1 annotations, document model, and Swagger UI
helpers for Dart servers.

## Install

Most apps get core transitively — `axle_relic`, `axle_shelf`, and
`axle_serverpod` re-export it. Depend on it directly only when building an
adapter or using the document model standalone:

```yaml
dependencies:
  axle_core: ^0.2.0
```

```dart
import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  pathParams: [ApiPathParam('id', type: int)],
  responses: [ApiResponse.ok(UserDto)],
)
Future<Result> getUser(Request request) async { ... }
```

`OpenApiSchema`, `OpenApiDocument`, and the annotation classes have no framework
dependencies. The model covers security schemes and requirements, response
headers, multiple media types, parameter/property constraints, and `oneOf`
discriminators. `swaggerUiHtml` returns a standalone HTML shell that loads
Swagger UI from a CDN and points it at a spec URL.

Security metadata is declarative. Define schemes once and reference them from
`@ApiRoute`; enforcement stays in the application.

## Adapter contract

`AxleDocs` is the framework-neutral payload for an adapter. It normalizes paths,
derives the UI title from the spec, applies the default no-cache policy, and
renders the Swagger UI HTML:

```dart
final docs = AxleDocs(spec: axleOpenApiJson);

docs.specJson; // exact generated artifact
docs.specPath; // /openapi.json
docs.docsPath; // /docs
docs.uiHtml;   // standalone Swagger UI HTML
docs.headers;  // {'cache-control': 'no-store'}
```

Adapters only translate these values into their framework's response type. See
the [adapter authoring guide](https://github.com/infm5/axle/blob/master/docs/adapter-authoring.md) and the
`axle_relic`/`axle_shelf` packages for reference implementations.

The default Swagger UI URL is pinned to 5.34.0 and includes SRI hashes. For
offline deployments, run `axle gen` to write `generate.output.ui`, then pass
that directory to your adapter's `swaggerUiDirectory` option and set the
resulting URL with `swaggerUiUrl`.
