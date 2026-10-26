import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/twice',
  responses: [
    ApiResponse(status: 200, type: String),
    ApiResponse(status: 200, type: int),
  ],
)
Future<Object?> twice(Object? request) async => null;
