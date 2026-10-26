import 'package:axle_core/axle_core.dart';

class A {}

class B {}

@ApiSchema(oneOf: [A], anyOf: [B])
class Both {}

@ApiRoute(
  method: ApiMethod.get,
  path: '/both',
  responses: [ApiResponse.ok(Both)],
)
Future<Object?> both(Object? request) async => null;
