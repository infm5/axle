/// Checks that the paths in a generated spec reach real handlers.
///
/// An `@ApiRoute` path and the matching router registration are two strings,
/// and axle cannot see the router. If one changes alone the spec keeps
/// documenting a route that now answers `404`. [checkDocumentedRoutes] walks the
/// spec, calls every documented route, and reports the ones nothing answers.
library;

import 'dart:convert';

/// The methods that are safe to call against a real handler.
const safeRouteMethods = {'GET', 'HEAD', 'OPTIONS'};

/// One operation from a spec, with a path that can be requested.
class DocumentedRoute {
  /// Creates a route.
  const DocumentedRoute({
    required this.method,
    required this.path,
    required this.requestPath,
  });

  /// The upper-case HTTP method.
  final String method;

  /// The path as written in the spec, such as `/todos/{id}`.
  final String path;

  /// [path] with each parameter replaced by a sample value, such as
  /// `/todos/1`.
  final String requestPath;

  @override
  String toString() => '$method $path';
}

/// What a server answered.
class RouteResponse {
  /// Creates a response.
  const RouteResponse(this.status, {this.body = '', this.contentType});

  /// The HTTP status code.
  final int status;

  /// The response body as text.
  final String body;

  /// The `Content-Type` header, when present.
  final String? contentType;

  /// Whether this answer is indistinguishable from [other].
  bool sameAs(RouteResponse other) =>
      status == other.status &&
      body == other.body &&
      contentType == other.contentType;
}

/// Sends a request to the server under test.
///
/// Implementations call the handler directly or use an HTTP client. They return
/// whatever the server answered, including errors.
typedef RouteSender =
    Future<RouteResponse> Function(String method, String path);

/// Whether a documented route reached a handler.
enum RouteOutcome {
  /// Something other than the "no such route" fallback answered.
  routed,

  /// The server answered as it does for a path nobody registered.
  unrouted,
}

/// The result of calling one documented route.
class RouteReport {
  /// Creates a report.
  const RouteReport({
    required this.route,
    required this.response,
    required this.outcome,
  });

  /// The route that was called.
  final DocumentedRoute route;

  /// What the server answered.
  final RouteResponse response;

  /// Whether the route reached a handler.
  final RouteOutcome outcome;

  /// Whether the route reached a handler.
  bool get isRouted => outcome == RouteOutcome.routed;

  @override
  String toString() =>
      '${route.method} ${route.path} -> ${response.status} '
      '(${outcome.name})';
}

/// Lists the operations in [spec], a generated OpenAPI JSON document.
///
/// Only [methods] are returned. Path parameters are filled from the spec's own
/// `example`, `default`, or `enum` values, and from the schema type otherwise.
List<DocumentedRoute> documentedRoutes(
  String spec, {
  Set<String> methods = safeRouteMethods,
}) {
  final document = jsonDecode(spec) as Map<String, Object?>;
  final paths = (document['paths'] as Map<String, Object?>?) ?? const {};
  final wanted = {for (final method in methods) method.toUpperCase()};

  final routes = <DocumentedRoute>[];
  for (final MapEntry(key: path, value: item) in paths.entries) {
    final operations = item! as Map<String, Object?>;
    for (final MapEntry(key: method, value: operation) in operations.entries) {
      if (!wanted.contains(method.toUpperCase())) continue;
      final parameters = [
        for (final parameter
            in ((operation! as Map<String, Object?>)['parameters']
                    as List<Object?>?) ??
                const <Object?>[])
          if ((parameter! as Map<String, Object?>)['in'] == 'path')
            parameter as Map<String, Object?>,
      ];
      routes.add(
        DocumentedRoute(
          method: method.toUpperCase(),
          path: path,
          requestPath: _fill(path, parameters, document),
        ),
      );
    }
  }
  return routes;
}

/// Calls every documented route in [spec] through [send] and reports which ones
/// reach a handler.
///
/// A route is [RouteOutcome.unrouted] when the server answers exactly as it does
/// for a path nobody registered (same status, body, and media type), or with
/// `405`. A handler that answers `404` with its own body, such as "no such
/// todo", still counts as routed.
///
/// By default only [safeRouteMethods] are called. Pass more [methods] only
/// against a server whose state you can throw away, because calling `POST`,
/// `PUT`, `PATCH`, or `DELETE` runs the real handler.
Future<List<RouteReport>> checkDocumentedRoutes(
  String spec,
  RouteSender send, {
  Set<String> methods = safeRouteMethods,
}) async {
  final probes = <String, RouteResponse>{};
  final reports = <RouteReport>[];
  for (final route in documentedRoutes(spec, methods: methods)) {
    final probe =
        probes[route.method] ??= await send(
          route.method,
          '/__axle_unrouted_probe__',
        );
    final response = await send(route.method, route.requestPath);
    final unrouted =
        (response.status == 405 && probe.status != 405) ||
        response.sameAs(probe);
    reports.add(
      RouteReport(
        route: route,
        response: response,
        outcome: unrouted ? RouteOutcome.unrouted : RouteOutcome.routed,
      ),
    );
  }
  return reports;
}

String _fill(
  String path,
  List<Map<String, Object?>> parameters,
  Map<String, Object?> document,
) {
  return path.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
    final name = match.group(1)!;
    final parameter = parameters.firstWhere(
      (candidate) => candidate['name'] == name,
      orElse: () => const {},
    );
    return _render(name, parameter, document);
  });
}

String _render(
  String name,
  Map<String, Object?> parameter,
  Map<String, Object?> document,
) {
  final schema = _resolve(parameter['schema'], document);
  final value = parameter['example'] ?? _sample(schema, document);
  final style = parameter['style'] as String? ?? 'simple';

  String encode(Object? scalar) => Uri.encodeComponent('$scalar');
  final items = value is List ? value : [value];
  final joined = items.map(encode).join(',');
  return switch (style) {
    'label' => '.${items.map(encode).join('.')}',
    'matrix' => ';$name=$joined',
    _ => joined,
  };
}

Object? _sample(Map<String, Object?> schema, Map<String, Object?> document) {
  if (schema.containsKey('example')) return schema['example'];
  if (schema.containsKey('default')) return schema['default'];
  final enumValues = schema['enum'];
  if (enumValues is List && enumValues.isNotEmpty) {
    return enumValues.firstWhere((value) => value != null, orElse: () => '');
  }
  final rawType = schema['type'];
  final type =
      rawType is List
          ? rawType.firstWhere((t) => t != 'null', orElse: () => 'string')
          : rawType;
  switch (type) {
    case 'integer':
      return (schema['minimum'] as num?)?.toInt().clamp(1, 1 << 31) ?? 1;
    case 'number':
      return (schema['minimum'] as num?) ?? 1;
    case 'boolean':
      return true;
    case 'array':
      final items = _resolve(schema['items'], document);
      return [_sample(items, document)];
  }
  return switch (schema['format']) {
    'uuid' => '00000000-0000-4000-8000-000000000000',
    'date' => '2026-01-01',
    'date-time' => '2026-01-01T00:00:00Z',
    'email' => 'a@example.com',
    'ipv4' => '192.0.2.1',
    _ => 'x' * ((schema['minLength'] as int?) ?? 1).clamp(1, 64),
  };
}

Map<String, Object?> _resolve(Object? schema, Map<String, Object?> document) {
  if (schema is! Map<String, Object?>) return const {};
  final ref = schema[r'$ref'];
  if (ref is String && ref.startsWith('#/components/schemas/')) {
    final components = document['components'] as Map<String, Object?>?;
    final schemas = components?['schemas'] as Map<String, Object?>?;
    final target = schemas?[ref.substring('#/components/schemas/'.length)];
    return target is Map<String, Object?> ? target : const {};
  }
  return schema;
}
