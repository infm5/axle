import 'dart:io';

import 'package:axle_relic/axle_relic.dart';
import 'package:path/path.dart' as p;
import 'package:relic/relic.dart';
import 'package:test/test.dart';

const _spec =
    '{"openapi":"3.1.0","info":{"title":"Test","version":"1.0.0"},"paths":{}}';

const _contractSpec = '''
{
  "openapi": "3.1.0",
  "info": {"title": "Contract", "version": "1.0.0"},
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
  group('mountAxleDocs', () {
    test('serves the generated spec as JSON', () async {
      final app = RelicApp()..mountAxleDocs(spec: _spec);

      final response = await _response(
        _handlerFor(app, '/openapi.json'),
        '/openapi.json',
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), _spec);
      expect(response.headers['cache-control'], contains('no-store'));
    });

    test('serves richer contracts verbatim', () async {
      final app = RelicApp()..mountAxleDocs(spec: _contractSpec);

      final response = await _response(
        _handlerFor(app, '/openapi.json'),
        '/openapi.json',
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), _contractSpec);
    });

    test('derives the UI title from the spec when title is omitted', () async {
      final app = RelicApp()..mountAxleDocs(spec: _spec);

      final response = await _response(_handlerFor(app, '/docs'), '/docs');
      final html = await response.readAsString();

      expect(html, contains('<title>Test</title>'));
    });

    test('serves Swagger UI and points it at the spec route', () async {
      final app = RelicApp()
        ..mountAxleDocs(spec: _spec, title: 'Axle Test API');

      final response = await _response(_handlerFor(app, '/docs'), '/docs');

      expect(response.statusCode, 200);
      final html = await response.readAsString();
      expect(html, contains('<title>Axle Test API</title>'));
      expect(html, contains('url: "/openapi.json"'));
      expect(html, contains('SwaggerUIBundle'));
    });

    test('rejects empty paths', () {
      final app = RelicApp();

      expect(
        () => app.mountAxleDocs(spec: _spec, specPath: '  '),
        throwsArgumentError,
      );
    });

    test('mounts local Swagger UI assets from a generated directory', () async {
      final directory = Directory.systemTemp.createTempSync('axle_relic_ui_');
      addTearDown(() => directory.deleteSync(recursive: true));
      File(
        p.join(directory.path, 'swagger-ui.css'),
      ).writeAsStringSync('body{}');
      final app = RelicApp()
        ..mountSwaggerUiAssets(directory.path, pathPrefix: 'assets/');

      final response = await _response(
        _handlerFor(app, '/assets/swagger-ui.css'),
        '/assets/swagger-ui.css',
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'body{}');
      expect(response.mimeType?.primaryType, 'text');
      expect(response.mimeType?.subType, 'css');
      expect(response.headers['cache-control'], contains('no-store'));
    });

    test('mountAxleDocs serves local Swagger UI assets', () async {
      final directory = Directory.systemTemp.createTempSync('axle_relic_ui_');
      addTearDown(() => directory.deleteSync(recursive: true));
      File(
        p.join(directory.path, 'swagger-ui.css'),
      ).writeAsStringSync('body{}');
      final app = RelicApp()
        ..mountAxleDocs(spec: _spec, swaggerUiDirectory: directory.path);

      final ui = await _response(_handlerFor(app, '/docs'), '/docs');
      expect(await ui.readAsString(), contains('/docs-assets/swagger-ui.css'));
      final asset = await _response(
        _handlerFor(app, '/docs-assets/swagger-ui.css'),
        '/docs-assets/swagger-ui.css',
      );
      expect(asset.statusCode, 200);
      expect(await asset.readAsString(), 'body{}');
    });

    test('normalizes custom paths and uses them in the UI', () async {
      final app = RelicApp()
        ..mountAxleDocs(
          spec: _spec,
          specPath: 'api/openapi.json',
          docsPath: 'api/docs',
        );

      final specResponse = await _response(
        _handlerFor(app, '/api/openapi.json'),
        '/api/openapi.json',
      );
      expect(specResponse.statusCode, 200);
      expect(await specResponse.readAsString(), _spec);

      final docsResponse = await _response(
        _handlerFor(app, '/api/docs'),
        '/api/docs',
      );
      final html = await docsResponse.readAsString();
      expect(html, contains('url: "/api/openapi.json"'));
    });
  });

  group('standalone handlers', () {
    test('openApiJsonHandler returns JSON', () async {
      final handler = openApiJsonHandler(_spec, noCache: false);
      final response = await _response(handler, '/openapi.json');
      expect(await response.readAsString(), _spec);
      expect(response.headers['cache-control'], isNull);
    });

    test('swaggerUiHandler returns HTML', () async {
      final handler = swaggerUiHandler(specPath: '/spec.json');
      final response = await _response(handler, '/docs');
      expect(response.mimeType, MimeType.html);
      final html = await response.readAsString();
      expect(html, contains('<title>API Docs</title>'));
      expect(html, contains('url: "/spec.json"'));
    });
  });
}

Handler _handlerFor(RelicApp app, String path) {
  final result = app.lookup(Method.get, path);
  if (result is! RouterMatch<Handler>) {
    throw StateError('No route for $path: $result');
  }
  return result.value;
}

Future<Response> _response(Handler handler, String path) async {
  final result = await handler(_request(path));
  return result as Response;
}

Request _request(String path) => RequestInternal.create(
  Method.get,
  Uri.parse('http://localhost$path'),
  Object(),
);
