import 'package:axle_serverpod/axle_serverpod.dart';

import 'src/api/greeting_api.dart';
import 'src/axle/openapi.g.dart';
import 'src/generated/serverpod.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod. The generated Serverpod class is already connected
  // with your project's generated code.
  final pod = Serverpod(args);

  // Register the REST greeting route and the axle docs routes on the web
  // server. The docs and the REST route share the same web server port.
  pod.webServer
    ..addRoute(GreetingRoute(), greetingPath)
    ..mountAxleDocs(
      docsPath: '/swagger',
      spec: axleOpenApiJson,
      swaggerUiDirectory: 'assets/swagger-ui',
    );

  // Start the server.
  await pod.start();
}
