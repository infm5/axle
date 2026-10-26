/// Keeps the `@ApiRoute` paths and the Shelf router in step.
///
/// The annotation writes `/notes/<id>` and the router registers `/notes/<id>`
/// too, but they are two strings. This test fails if one changes alone.
library;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_todo_example/api.dart';
import 'package:shelf_todo_example/src/generated/openapi.g.dart';
import 'package:test/test.dart';

void main() {
  test('every documented route reaches a handler', () async {
    final router = Router();
    configureApi(router);

    // Only GET, HEAD, and OPTIONS by default, so no handler changes state.
    final reports = await checkShelfRoutes(router.call, spec: axleOpenApiJson);

    expect(reports, isNotEmpty);
    expect(
      reports.where((report) => !report.isRouted).map((r) => '$r'),
      isEmpty,
    );
  });
}
