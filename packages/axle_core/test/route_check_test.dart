import 'dart:convert';

import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

String _spec(Map<String, Object?> paths, [Map<String, Object?>? components]) =>
    jsonEncode({
      'openapi': '3.1.0',
      'info': {'title': 't', 'version': '1'},
      'paths': paths,
      if (components != null) 'components': components,
    });

Map<String, Object?> _get(List<Map<String, Object?>> parameters) => {
  'get': {'parameters': parameters},
};

Map<String, Object?> _path(String name, Map<String, Object?> rest) => {
  'name': name,
  'in': 'path',
  'required': true,
  ...rest,
};

void main() {
  group('documentedRoutes', () {
    String requestPath(Map<String, Object?> parameter, {String name = 'p'}) {
      final routes = documentedRoutes(
        _spec({
          '/x/{$name}': _get([parameter]),
        }),
      );
      return routes.single.requestPath;
    }

    test('fills an integer from its minimum', () {
      expect(
        requestPath(
          _path('p', {
            'schema': {'type': 'integer', 'minimum': 5},
          }),
        ),
        '/x/5',
      );
      expect(
        requestPath(
          _path('p', {
            'schema': {'type': 'integer'},
          }),
        ),
        '/x/1',
      );
    });

    test('prefers an example, then a default, then an enum value', () {
      expect(
        requestPath(
          _path('p', {
            'example': 'e',
            'schema': {'type': 'string'},
          }),
        ),
        '/x/e',
      );
      expect(
        requestPath(
          _path('p', {
            'schema': {'type': 'string', 'default': 'd'},
          }),
        ),
        '/x/d',
      );
      expect(
        requestPath(
          _path('p', {
            'schema': {
              'enum': ['a', 'b'],
            },
          }),
        ),
        '/x/a',
      );
    });

    test('knows common string formats', () {
      expect(
        requestPath(
          _path('p', {
            'schema': {'type': 'string', 'format': 'uuid'},
          }),
        ),
        '/x/00000000-0000-4000-8000-000000000000',
      );
      expect(
        requestPath(
          _path('p', {
            'schema': {'type': 'string', 'format': 'date'},
          }),
        ),
        '/x/2026-01-01',
      );
    });

    test('respects minLength', () {
      expect(
        requestPath(
          _path('p', {
            'schema': {'type': 'string', 'minLength': 3},
          }),
        ),
        '/x/xxx',
      );
    });

    test('renders arrays in the declared style', () {
      final array = {
        'type': 'array',
        'items': {'type': 'integer'},
      };
      expect(
        requestPath(
          _path('p', {
            'schema': array,
            'example': [1, 2],
          }),
        ),
        '/x/1,2',
      );
      expect(
        requestPath(
          _path('p', {
            'schema': array,
            'style': 'label',
            'example': [1, 2],
          }),
        ),
        '/x/.1.2',
      );
      expect(
        requestPath(
          _path('p', {
            'schema': array,
            'style': 'matrix',
            'example': [1, 2],
          }),
        ),
        '/x/;p=1,2',
      );
    });

    test('follows a schema reference', () {
      final spec = _spec(
        {
          '/x/{p}': _get([
            _path('p', {
              'schema': {r'$ref': '#/components/schemas/Kind'},
            }),
          ]),
        },
        {
          'schemas': {
            'Kind': {
              'type': 'string',
              'enum': ['user', 'team'],
            },
          },
        },
      );
      expect(documentedRoutes(spec).single.requestPath, '/x/user');
    });

    test('encodes unsafe characters', () {
      expect(
        requestPath(
          _path('p', {
            'example': 'a b/c',
            'schema': {'type': 'string'},
          }),
        ),
        '/x/a%20b%2Fc',
      );
    });

    test('defaults to the safe methods', () {
      final spec = _spec({
        '/a': {'get': {}, 'post': {}, 'delete': {}, 'head': {}},
      });
      expect(
        documentedRoutes(spec).map((route) => route.method),
        unorderedEquals(['GET', 'HEAD']),
      );
      expect(
        documentedRoutes(
          spec,
          methods: {'post', 'DELETE'},
        ).map((r) => r.method),
        unorderedEquals(['POST', 'DELETE']),
      );
    });

    test('lists a path with no parameters unchanged', () {
      final route =
          documentedRoutes(
            _spec({
              '/health': {'get': {}},
            }),
          ).single;
      expect(route.path, '/health');
      expect(route.requestPath, '/health');
      expect(route.toString(), 'GET /health');
    });
  });

  group('checkDocumentedRoutes', () {
    const fallback = RouteResponse(
      404,
      body: 'Not Found',
      contentType: 'text/plain',
    );

    final spec = _spec({
      '/todos': {'get': {}},
      '/todos/{id}': _get([
        _path('id', {
          'schema': {'type': 'integer'},
        }),
      ]),
      '/renamed': {'get': {}},
      '/wrong-method': {'get': {}},
    });

    /// A server that knows `/todos` and `/todos/{id}` and nothing else.
    Future<RouteResponse> server(String method, String path) async {
      if (path == '/todos') {
        return const RouteResponse(
          200,
          body: '[]',
          contentType: 'application/json',
        );
      }
      if (path.startsWith('/todos/')) {
        // The handler runs and decides there is no such todo.
        return const RouteResponse(
          404,
          body: '{"error":"no such todo"}',
          contentType: 'application/json',
        );
      }
      if (path == '/wrong-method') {
        return const RouteResponse(405, body: 'Method Not Allowed');
      }
      return fallback;
    }

    late Map<String, RouteReport> reports;
    setUp(() async {
      reports = {
        for (final report in await checkDocumentedRoutes(spec, server))
          report.route.path: report,
      };
    });

    test('a route a handler answers is routed', () {
      expect(reports['/todos']!.isRouted, isTrue);
    });

    test('a handler that answers 404 with its own body is still routed', () {
      expect(reports['/todos/{id}']!.isRouted, isTrue);
      expect(reports['/todos/{id}']!.response.status, 404);
    });

    test('a path nobody registered is unrouted', () {
      expect(reports['/renamed']!.outcome, RouteOutcome.unrouted);
    });

    test('a documented method the server refuses is unrouted', () {
      expect(reports['/wrong-method']!.outcome, RouteOutcome.unrouted);
    });

    test('reports say what was called', () {
      expect(reports['/renamed']!.toString(), 'GET /renamed -> 404 (unrouted)');
    });

    test('probes each method once', () async {
      final calls = <String>[];
      await checkDocumentedRoutes(spec, (method, path) async {
        calls.add('$method $path');
        return fallback;
      });
      expect(
        calls.where((call) => call.contains('__axle_unrouted_probe__')),
        hasLength(1),
      );
    });
  });
}
