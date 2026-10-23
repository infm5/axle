import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/duplicate-status',
  responses: [ApiResponse(status: 200), ApiResponse(status: 200)],
)
Future<Object?> duplicateStatus(Object? request) async => null;
