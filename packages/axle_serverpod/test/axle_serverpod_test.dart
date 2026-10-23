import 'dart:io';

import 'package:axle_serverpod/axle_serverpod.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

const _spec =
    '{"openapi":"3.1.0","info":{"title":"Test API","version":"1.0.0"},'
    '"paths":{}}';

void main() {
  group('openApiJsonResponse', () {
    test('serves the spec as JSON with no-store', () async {
      final response = openApiJsonResponse(AxleDocs(spec: _spec));

      expect(response.statusCode, 200);
      expect(await response.readAsString(), _spec);
      expect(response.mimeType, MimeType.json);
      expect(response.headers.cacheControl?.noStore, isTrue);
    });

    test('omits cache headers when noCache is false', () {
      final response = openApiJsonResponse(
        AxleDocs(spec: _spec, noCache: false),
      );

      expect(response.headers.cacheControl, isNull);
    });
  });

  group('swaggerUiResponse', () {
    test('serves HTML with the spec title', () async {
      final html = await swaggerUiResponse(
        AxleDocs(spec: _spec),
      ).readAsString();

      expect(html, contains('<title>Test API</title>'));
      expect(html, contains('url: "/openapi.json"'));
      expect(html, contains('cdn.jsdelivr.net'));
    });

    test('uses a local asset base URL', () async {
      final docs = AxleDocs(spec: _spec, swaggerUiUrl: '/docs-assets');
      final html = await swaggerUiResponse(docs).readAsString();

      expect(html, contains('/docs-assets/swagger-ui.css'));
      expect(html, isNot(contains('cdn.jsdelivr.net')));
    });
  });

  group('routes', () {
    test('respond to GET at the mount root', () {
      final docs = AxleDocs(spec: _spec);
      final ui = AxleDocsRoute(docs);
      final spec = AxleOpenApiRoute(docs);

      expect(ui.methods, {Method.get});
      expect(spec.methods, {Method.get});
      expect(ui.path, '/');
      expect(spec.path, '/');
      expect(ui.docs, same(docs));
      expect(spec.docs, same(docs));
    });
  });

  group('mountAxleDocs', () {
    test('registers the spec and UI routes', () {
      final server = _RecordingWebServer();

      final docs = server.mountAxleDocs(spec: _spec);

      expect(docs.specPath, '/openapi.json');
      expect(docs.docsPath, '/docs');
      expect(server.routes.map((route) => route.$2), [
        '/openapi.json',
        '/docs',
      ]);
      expect(server.routes[0].$1, isA<AxleOpenApiRoute>());
      expect(server.routes[1].$1, isA<AxleDocsRoute>());
    });

    test('normalizes custom paths and title', () {
      final server = _RecordingWebServer();

      final docs = server.mountAxleDocs(
        spec: _spec,
        specPath: 'api/openapi.json',
        docsPath: 'api/docs',
        title: 'Custom Docs',
      );

      expect(docs.specPath, '/api/openapi.json');
      expect(docs.docsPath, '/api/docs');
      expect(docs.title, 'Custom Docs');
      expect(server.routes.map((route) => route.$2), [
        '/api/openapi.json',
        '/api/docs',
      ]);
    });

    test('registers a static route for local UI assets', () {
      final directory = _assetsDirectory();
      final server = _RecordingWebServer();

      server.mountAxleDocs(spec: _spec, swaggerUiDirectory: directory.path);

      expect(server.routes.map((route) => route.$2), [
        '/openapi.json',
        '/docs',
        '/docs-assets',
      ]);
      expect(server.routes.last.$1, isA<StaticRoute>());
    });

    test('mounts every route under a custom prefix', () {
      final directory = _assetsDirectory();
      final server = _RecordingWebServer();

      final docs = server.mountAxleDocs(
        spec: _spec,
        specPath: '/internal/api/openapi.json',
        docsPath: '/internal/api/reference',
        swaggerUiDirectory: directory.path,
        swaggerUiPath: '/internal/api/assets',
      );

      expect(server.routes.map((route) => route.$2), [
        '/internal/api/openapi.json',
        '/internal/api/reference',
        '/internal/api/assets',
      ]);
      expect(docs.uiHtml, contains('url: "/internal/api/openapi.json"'));
      expect(docs.uiHtml, contains('/internal/api/assets/swagger-ui.css'));
    });

    test('accepts a custom CDN for the UI assets', () {
      final server = _RecordingWebServer();

      final docs = server.mountAxleDocs(
        spec: _spec,
        swaggerUiUrl: 'https://cdn.example.com/swagger-ui',
      );

      expect(server.routes, hasLength(2));
      expect(
        docs.uiHtml,
        contains('https://cdn.example.com/swagger-ui/swagger-ui.css'),
      );
    });

    test('rejects an asset path that collides with a docs path', () {
      final directory = _assetsDirectory();
      final server = _RecordingWebServer();

      expect(
        () => server.mountAxleDocs(
          spec: _spec,
          swaggerUiDirectory: directory.path,
          swaggerUiPath: '/docs',
        ),
        throwsArgumentError,
      );
      expect(server.routes, isEmpty);
    });

    test('rejects a missing asset directory', () {
      final server = _RecordingWebServer();

      expect(
        () => server.mountAxleDocs(
          spec: _spec,
          swaggerUiDirectory: '/does/not/exist',
        ),
        throwsArgumentError,
      );
      expect(server.routes, isEmpty);
    });

    test('rejects an empty asset directory', () {
      final directory = Directory.systemTemp.createTempSync('axle_serverpod_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final server = _RecordingWebServer();

      expect(
        () => server.mountAxleDocs(
          spec: _spec,
          swaggerUiDirectory: directory.path,
        ),
        throwsArgumentError,
      );
      expect(server.routes, isEmpty);
    });
  });

  group('mountSwaggerUiAssets', () {
    test('normalizes the prefix and registers a static route', () {
      final directory = _assetsDirectory();
      final server = _RecordingWebServer();

      server.mountSwaggerUiAssets(directory.path, pathPrefix: 'assets/');

      expect(server.routes.single.$2, '/assets');
      expect(server.routes.single.$1, isA<StaticRoute>());
    });

    test('rejects an empty directory', () {
      final directory = Directory.systemTemp.createTempSync('axle_serverpod_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final server = _RecordingWebServer();

      expect(
        () => server.mountSwaggerUiAssets(directory.path),
        throwsArgumentError,
      );
    });

    test('rejects an empty prefix', () {
      final server = _RecordingWebServer();

      expect(
        () => server.mountSwaggerUiAssets('/tmp', pathPrefix: ' '),
        throwsArgumentError,
      );
    });
  });
}

Directory _assetsDirectory() {
  final directory = Directory.systemTemp.createTempSync('axle_serverpod_');
  addTearDown(() => directory.deleteSync(recursive: true));
  File('${directory.path}/swagger-ui.css').writeAsStringSync('body{}');
  return directory;
}

class _RecordingWebServer implements WebServer {
  final routes = <(Route, String)>[];

  @override
  void addRoute(Route route, [String path = '/']) {
    routes.add((route, path));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
