/// Registers every showcase route.
library;

import 'package:shelf_router/shelf_router.dart';

import 'header_routes.dart';
import 'media_routes.dart';
import 'parameter_routes.dart';
import 'response_routes.dart';
import 'schema_routes.dart';
import 'security_routes.dart';

/// Registers the showcase routes on [router].
void configureApi(Router router) {
  mediaRoutes(router);
  headerRoutes(router);
  parameterRoutes(router);
  securityRoutes(router);
  schemaRoutes(router);
  responseRoutes(router);
}
