# Framework Setup Recipes

Use the adapter package matching the server. Every adapter re-exports
`axle_core`, so application code imports annotations from the adapter.

## Relic

```yaml
dependencies:
  axle_relic: ^0.3.0
  relic: ^2.0.0-rc.2

dev_dependencies:
  axle_cli: ^0.3.0
```

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

Relic 2 is currently a release candidate. Keep the `^2.0.0-rc.2` constraint
until the stable 2.x line is available.

Custom paths:

```dart
app.mountAxleDocs(
  spec: axleOpenApiJson,
  specPath: '/api/openapi.json',
  docsPath: '/api/docs',
  swaggerUiDirectory: 'assets/swagger-ui',
  swaggerUiPath: '/api/docs-assets',
);
```

The local asset prefix must not be `/`, the spec path, or the docs path.

## Shelf

```yaml
dependencies:
  axle_shelf: ^0.3.0
  shelf: ^1.4.3

dev_dependencies:
  axle_cli: ^0.3.0
```

```dart
import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:your_package/src/generated/openapi.g.dart';

final router = Router()..get('/users/<id>', getUser);
final docs = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);

final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addHandler(Cascade().add(docs).add(router.call).handler);
```

`axleDocsHandler` returns `404` for unrelated paths and non-`GET` requests, so
it composes cleanly with a router or `Cascade`. Put the docs handler **before**
the router in the cascade: Shelf's `Cascade` treats a `404` as “not handled,” so
a router-first order can swallow an intentional API `404` and replace it with
the docs handler's `404`.

For annotated Shelf routes, use Shelf's router syntax in the shared path
constant:

```dart
const userPath = '/users/<id>';
```

axle normalizes `<id>` to `{id}` in the generated OpenAPI path, so the
annotation and router can share one constant.

Standalone handlers:

```dart
final docs = AxleDocs(spec: axleOpenApiJson);

router
  ..get(docs.specPath, openApiJsonHandler(docs))
  ..get(docs.docsPath, swaggerUiHandler(docs));
```

## Serverpod 4 web routes

```yaml
dependencies:
  axle_serverpod: ^0.3.0
  serverpod: ^4.0.0

dev_dependencies:
  axle_cli: ^0.3.0
```

Serverpod has two HTTP surfaces:

- **API-server endpoints** (`Endpoint` subclasses) speak the Serverpod protocol
  over POST. axle cannot document these as REST.
- **Web-server routes** (`Route` subclasses) are ordinary HTTP and are what axle
  documents.

Annotate a top-level function and delegate from the route:

```dart
import 'package:axle_serverpod/axle_serverpod.dart';
import 'package:your_package/src/generated/openapi.g.dart';

const greetingPath = '/greeting';

@ApiRoute(
  method: ApiMethod.get,
  path: greetingPath,
  responses: [ApiResponse.ok(GreetingDto)],
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

void run(List<String> args) async {
  final pod = Serverpod(args);
  pod.webServer
    ..addRoute(GreetingRoute(), greetingPath)
    ..mountAxleDocs(
      spec: axleOpenApiJson,
      docsPath: '/swagger',
      swaggerUiDirectory: 'assets/swagger-ui',
    );
  await pod.start();
}
```

The docs run on the **web-server port** (often `8082`), not the API-server port
(often `8090`) or Insights. `serverpod start` lists Endpoint methods, not
web-server `Route`s, so the docs will not appear in that explorer.

## Custom adapter

For any other Dart HTTP framework, depend on core and CLI:

```yaml
dependencies:
  axle_core: ^0.3.0

dev_dependencies:
  axle_cli: ^0.3.0
```

Then serve the shared `AxleDocs` contract:

```dart
final docs = AxleDocs(spec: axleOpenApiJson);

docs.specJson; // JSON document
docs.specPath; // /openapi.json
docs.docsPath; // /docs
docs.uiHtml;   // Swagger UI shell
docs.headers;  // cache headers

// Local UI assets live in generate.output.ui and are served by the adapter.
```

A real adapter should expose the spec, UI, and optional asset routes through its
framework's response type. Read the
[adapter authoring guide](https://github.com/infm5/axle/blob/master/docs/adapter-authoring.md)
before implementing one.

## Assets and serving checklist

- Run `axle gen` before starting the server; the local asset directory must
  exist.
- Pass `swaggerUiDirectory` to self-host; omit it to use the pinned CDN UI.
- Relative asset paths resolve from the process working directory.
- Use absolute paths in deployment when the working directory is uncertain.
- Keep the spec path, docs path, and asset prefix distinct.
- Verify both `/openapi.json` and `/docs` on the actual framework port.
