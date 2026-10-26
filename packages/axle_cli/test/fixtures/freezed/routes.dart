import 'package:axle_core/axle_core.dart';

import 'models.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/people',
  responses: [ApiResponse.ok(Person)],
)
Future<Object?> people(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/shapes',
  responses: [ApiResponse.ok(Shape)],
)
Future<Object?> shapes(Object? request) async => null;
