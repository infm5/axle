import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/invalid-status',
  responses: [ApiResponse(status: 42)],
)
Future<Object?> invalidStatus(Object? request) async => null;
