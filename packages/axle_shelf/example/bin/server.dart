import 'dart:io';

import 'package:axle_shelf/axle_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_todo_example/api.dart';
import 'package:shelf_todo_example/src/generated/openapi.g.dart';

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
  stdout.writeln('Shelf Todo API listening on http://localhost:$port');
  stdout.writeln(
    'Shelf Todo API Docs(Swagger) listening on http://localhost:$port/docs',
  );
  stdout.writeln(
    'Shelf Todo API (OpenAPI specs) listening on '
    'http://localhost:$port/openapi.json',
  );
  stdout.writeln('Swagger UI assets listening on /docs-assets');
}
