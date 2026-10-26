import 'dart:io';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:showcase_example/api.dart';
import 'package:showcase_example/src/generated/openapi.g.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final router = Router();
  configureApi(router);

  final docs = axleDocsHandler(
    spec: axleOpenApiJson,
    swaggerUiDirectory: 'assets/swagger-ui',
  );
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(Cascade().add(router.call).add(docs).handler);

  await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Showcase API on http://localhost:$port (docs at /docs)');
}
