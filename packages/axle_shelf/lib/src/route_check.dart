/// Checks the documented routes of a Shelf application.
library;

import 'package:axle_core/axle_core.dart';
import 'package:shelf/shelf.dart';

/// Calls every route in [spec] on [handler] and reports which ones reach a
/// handler.
///
/// This is how you keep `@ApiRoute` paths and your router in step: if a route
/// is renamed in one place only, the spec still documents it but [handler]
/// answers like it does for any unknown path, and the report says so.
///
/// ```dart
/// test('every documented route is served', () async {
///   final reports = await checkShelfRoutes(router.call, spec: axleOpenApiJson);
///   expect(reports.where((r) => !r.isRouted), isEmpty);
/// });
/// ```
///
/// Only [safeRouteMethods] (`GET`, `HEAD`, `OPTIONS`) are called by default.
/// Pass [methods] to include `POST`, `PUT`, `PATCH`, or `DELETE` when the
/// handler runs against state you can throw away; those run the real handler.
///
/// A handler that throws is reported as routed, because something did answer.
Future<List<RouteReport>> checkShelfRoutes(
  Handler handler, {
  required String spec,
  Set<String> methods = safeRouteMethods,
}) {
  return checkDocumentedRoutes(spec, (method, path) async {
    try {
      final response = await handler(
        Request(method, Uri.parse('http://localhost$path')),
      );
      return RouteResponse(
        response.statusCode,
        body: method == 'HEAD' ? '' : await response.readAsString(),
        contentType: response.headers['content-type'],
      );
    } on Object catch (error) {
      return RouteResponse(500, body: 'handler threw: $error');
    }
  }, methods: methods);
}
