import 'dart:io';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _spec =
    '{"openapi":"3.1.0","info":{"title":"Test API","version":"1.0.0"},'
    '"paths":{}}';

const _contractSpec = '''
{
  "openapi": "3.1.0",
  "info": {"title": "Contract API", "version": "1.0.0"},
  "components": {
    "securitySchemes": {
      "apiKey": {"type": "apiKey", "in": "header", "name": "X-API-Key"}
    }
  },
  "paths": {
    "/secure": {
      "get": {
        "security": [{"apiKey": []}],
        "responses": {
          "200": {
            "description": "OK",
            "headers": {
              "X-Total-Count": {"schema": {"type": "integer"}}
            }
          }
        }
      }
    }
  }
}
''';

void main() {
  group('axleDocsHandler', () {
    test('serves the spec and UI', () async {
      final handler = axleDocsHandler(spec: _spec);

      final specResponse = await _get(handler, '/openapi.json');
      expect(specResponse.statusCode, 200);
      expect(await specResponse.readAsString(), _spec);
      expect(specResponse.headers['content-type'], 'application/json');
      expect(specResponse.headers['cache-control'], 'no-store');

      final uiResponse = await _get(handler, '/docs');
      expect(uiResponse.statusCode, 200);
      expect(uiResponse.headers['content-type'], 'text/html; charset=utf-8');
      expect(
        await uiResponse.readAsString(),
        contains('<title>Test API</title>'),
      );
    });

    test('serves richer contracts verbatim', () async {
      final handler = axleDocsHandler(spec: _contractSpec);

      final specResponse = await _get(handler, '/openapi.json');

      expect(specResponse.statusCode, 200);
      expect(await specResponse.readAsString(), _contractSpec);
    });

    test('supports custom paths and no-cache disabled', () async {
      final handler = axleDocsHandler(
        spec: _spec,
        specPath: 'api/openapi.json',
        docsPath: 'api/docs',
        title: 'Custom Docs',
        noCache: false,
      );

      final specResponse = await _get(handler, '/api/openapi.json');
      expect(specResponse.statusCode, 200);
      expect(specResponse.headers['cache-control'], isNull);

      final uiResponse = await _get(handler, '/api/docs');
      expect(await uiResponse.readAsString(), contains('Custom Docs'));
    });

    test('returns 404 for unknown paths and methods', () async {
      final handler = axleDocsHandler(spec: _spec);

      expect((await _get(handler, '/missing')).statusCode, 404);
      final post = await handler(
        Request('POST', Uri.parse('http://localhost/openapi.json')),
      );
      expect(post.statusCode, 404);
    });
  });

  group('standalone handlers', () {
    test('openApiJsonHandler and swaggerUiHandler use AxleDocs', () async {
      final docs = AxleDocs(spec: _spec, title: 'standalone');

      final specResponse = await _get(
        openApiJsonHandler(docs),
        '/openapi.json',
      );
      expect(await specResponse.readAsString(), _spec);

      final uiResponse = await _get(swaggerUiHandler(docs), '/docs');
      expect(await uiResponse.readAsString(), contains('standalone'));
    });

    test('serves local Swagger UI assets from a generated directory', () async {
      final directory = Directory.systemTemp.createTempSync('axle_shelf_ui_');
      addTearDown(() => directory.deleteSync(recursive: true));
      File(
        p.join(directory.path, 'swagger-ui.css'),
      ).writeAsStringSync('body{}');
      final handler = swaggerUiAssetsHandler(
        directory.path,
        pathPrefix: 'assets/',
      );

      final response = await _get(handler, '/assets/swagger-ui.css');
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('text/css'));
      expect(response.headers['cache-control'], 'no-store');
      expect(await response.readAsString(), 'body{}');
    });

    test('axleDocsHandler embeds local Swagger UI assets', () async {
      final directory = Directory.systemTemp.createTempSync('axle_shelf_ui_');
      addTearDown(() => directory.deleteSync(recursive: true));
      File(
        p.join(directory.path, 'swagger-ui.css'),
      ).writeAsStringSync('body{}');

      final handler = axleDocsHandler(
        spec: _spec,
        swaggerUiDirectory: directory.path,
      );
      final ui = await _get(handler, '/docs');
      expect(await ui.readAsString(), contains('/docs-assets/swagger-ui.css'));

      final asset = await _get(handler, '/docs-assets/swagger-ui.css');
      expect(asset.statusCode, 200);
      expect(await asset.readAsString(), 'body{}');
    });
  });

  group('checkShelfRoutes', () {
    const spec = '''
{
  "openapi": "3.1.0",
  "info": {"title": "Routes", "version": "1.0.0"},
  "paths": {
    "/items": {"get": {}, "post": {}},
    "/items/{id}": {
      "get": {
        "parameters": [
          {"name": "id", "in": "path", "required": true,
           "schema": {"type": "integer"}}
        ]
      }
    },
    "/renamed": {"get": {}}
  }
}
''';

    /// Serves `/items` and `/items/<id>`; `/renamed` moved to `/new-name`.
    Future<Response> app(Request request) async {
      final path = '/${request.url.path}';
      if (path == '/items') return Response.ok('[]');
      if (path.startsWith('/items/')) {
        return Response.notFound('{"error":"no such item"}');
      }
      return Response.notFound('Not Found');
    }

    test('reports the documented route that nothing serves', () async {
      final reports = await checkShelfRoutes(app, spec: spec);
      final unrouted = reports.where((report) => !report.isRouted);
      expect(unrouted.map((report) => report.route.path), ['/renamed']);
    });

    test('a handler that 404s with its own body is routed', () async {
      final reports = await checkShelfRoutes(app, spec: spec);
      final byItem = reports.singleWhere(
        (report) => report.route.path == '/items/{id}',
      );
      expect(byItem.isRouted, isTrue);
      expect(byItem.route.requestPath, '/items/1');
      expect(byItem.response.status, 404);
    });

    test('only safe methods are called unless asked', () async {
      final seen = <String>[];
      await checkShelfRoutes((request) async {
        seen.add(request.method);
        return Response.ok('x');
      }, spec: spec);
      expect(seen.toSet(), {'GET'});

      seen.clear();
      await checkShelfRoutes(
        (request) async {
          seen.add(request.method);
          return Response.ok('x');
        },
        spec: spec,
        methods: {'GET', 'POST'},
      );
      expect(seen.toSet(), {'GET', 'POST'});
    });

    test('a handler that throws still counts as answering', () async {
      final reports = await checkShelfRoutes((request) async {
        if (request.url.path == 'items') throw StateError('boom');
        return Response.notFound('Not Found');
      }, spec: spec);
      final items = reports.singleWhere(
        (report) => report.route.path == '/items',
      );
      expect(items.isRouted, isTrue);
      expect(items.response.body, contains('boom'));
    });
  });
}

Future<Response> _get(Handler handler, String path) async {
  return await handler(Request('GET', Uri.parse('http://localhost$path')));
}
