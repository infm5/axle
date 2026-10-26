# Keeping paths in sync

An `@ApiRoute` path and the router registration that serves it are two strings.
They do not even look alike: `shelf_router` writes `/notes/<id>`, Relic writes
`/notes/:id`, and the spec writes `/notes/{id}`. axle normalizes all three in the
spec, but it cannot see your router. If a route is renamed in one place only, the
spec keeps documenting a path that now answers `404`, and nothing complains.

Two habits close the gap.

## 1. Share the path

Write the path once and use it in both places:

```dart
const notePath = '/notes/<id>';

@ApiRoute(method: ApiMethod.get, path: notePath, ...)
Future<Response> getNote(Request request, String id) async { ... }

router.get(notePath, getNote);
```

## 2. Test that every documented path is served

`checkShelfRoutes` walks the paths in your generated spec, calls each one on your
handler, and reports the ones nothing answers. It needs no running server:

```dart
import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';
import 'package:your_package/api.dart';
import 'package:your_package/src/generated/openapi.g.dart';

void main() {
  test('every documented route reaches a handler', () async {
    final router = Router();
    configureApi(router);

    final reports = await checkShelfRoutes(router.call, spec: axleOpenApiJson);

    expect(
      reports.where((report) => !report.isRouted).map((r) => '$r'),
      isEmpty,
    );
  });
}
```

A renamed route fails the test with a message like
`GET /notes/{id} -> 404 (unrouted)`, which names the operation to fix.

Path parameters are filled with a sample value from the spec: the parameter's
`example`, then its schema's `example`, `default`, or first `enum` value, and
finally a value of the right type (`1`, a UUID, a date, `x`). Arrays follow the
parameter's style, so a `label` array becomes `.1.2.3`.

### Safe methods only, by default

The check calls the real handler, so by default it sends only `GET`, `HEAD`, and
`OPTIONS`. To also check `POST`, `PUT`, `PATCH`, and `DELETE`, pass them
explicitly, and only against state you can throw away:

```dart
final reports = await checkShelfRoutes(
  router.call,
  spec: axleOpenApiJson,
  methods: {'GET', 'HEAD', 'OPTIONS', 'POST', 'PUT', 'PATCH', 'DELETE'},
);
```

The [showcase](https://github.com/infm5/axle/tree/master/examples/showcase) does
this for all 50 of its operations because it keeps its data in memory.

## Other frameworks

`checkShelfRoutes` is a thin wrapper over a function in `axle_core` that works
with any framework. Give it the spec and a function that sends a request and
returns what came back:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:axle_core/axle_core.dart';

Future<List<RouteReport>> checkMyServer(String spec, Uri base) async {
  final client = HttpClient();
  try {
    return await checkDocumentedRoutes(spec, (method, path) async {
      final request = await client.openUrl(method, base.resolve(path));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return RouteResponse(
        response.statusCode,
        body: body,
        contentType: response.headers.contentType?.mimeType,
      );
    });
  } finally {
    client.close();
  }
}
```

Start the server however your framework does, on a free port, and pass its base
URL. Relic and Serverpod apps can use this form.

## How a route is judged

Before calling the documented routes, the check asks for a path nobody can have
registered (`/__axle_unrouted_probe__`) and records exactly what the server
answers, for each HTTP method. A documented route is **unrouted** when the
server answers it the same way (same status, body, and media type), or with
`405 Method Not Allowed`. Anything else, including a `404` with a body of the
handler's own such as `{"error": "no such note"}`, means a handler ran.

This is why a route that looks up a resource and finds nothing still counts as
routed, while a mistyped path does not.

## Limits

- It proves a handler answers the path, not that the handler matches the spec.
  For that, compare real responses with the schemas. The showcase's conformance
  test is an example.
- A handler that answers a missing resource with exactly the fallback body of the
  server (for example plain `Not Found`) cannot be told apart from no handler.
- Authentication does not matter: a `401` means a handler ran.
- Routes registered only for methods the spec does not document are not found,
  because the check starts from the spec. To find routes that are served but
  undocumented, compare against your router's own list of routes.
