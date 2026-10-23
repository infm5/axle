import 'dart:io';

import 'package:axle_relic/axle_relic.dart';
import 'package:relic/relic.dart';
import 'package:relic_todo_example/api.dart';
import 'package:relic_todo_example/src/generated/openapi.g.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final app = RelicApp();
  configureApi(app);
  app.mountAxleDocs(
    spec: axleOpenApiJson,
    swaggerUiDirectory: 'assets/swagger-ui',
  );
  stdout.writeln('Todo API listening on http://localhost:$port');
  stdout.writeln(
    'Todo API Docs(Swagger) listening on http://localhost:$port/docs',
  );
  stdout.writeln(
    'Todo API (OpenAPI specs) listening on http://localhost:$port/openapi.json',
  );
  await app.serve(port: port);
}
