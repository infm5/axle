/// Checks that every path in the spec is served, so the `@ApiRoute` path and
/// the router registration cannot drift apart unnoticed.
library;

import 'dart:io';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:showcase_example/api.dart';
import 'package:test/test.dart';

void main() {
  final spec = File('openapi.json').readAsStringSync();

  Handler buildApp() {
    final router = Router();
    configureApi(router);
    return router.call;
  }

  test('every documented route reaches a handler', () async {
    // This server keeps its state in memory, so it is safe to call POST, PUT,
    // PATCH, and DELETE too. Against a real database, leave `methods` out.
    final reports = await checkShelfRoutes(
      buildApp(),
      spec: spec,
      methods: {'GET', 'HEAD', 'OPTIONS', 'POST', 'PUT', 'PATCH', 'DELETE'},
    );

    expect(reports.length, greaterThanOrEqualTo(50));
    expect(
      reports.where((report) => !report.isRouted).map((r) => '$r'),
      isEmpty,
      reason: 'A path in the spec no longer matches the router.',
    );
  });

  test('a renamed route is reported', () async {
    final app = buildApp();
    // Rename one route in the router only, as a refactor might: requests for
    // the documented path now reach a path nobody registered.
    Future<Response> drifted(Request request) async {
      if (request.url.path == 'media/logo') {
        return app(
          Request(
            request.method,
            Uri.parse('http://localhost/media/logo-renamed'),
          ),
        );
      }
      return app(request);
    }

    final reports = await checkShelfRoutes(drifted, spec: spec);
    final unrouted = reports.where((report) => !report.isRouted);
    expect(unrouted.map((report) => report.route.path), ['/media/logo']);
  });
}
