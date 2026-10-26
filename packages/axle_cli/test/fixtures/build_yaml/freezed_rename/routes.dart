import 'package:axle_core/axle_core.dart';

import 'account.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/all',
  responses: [
    ApiResponse(status: 200, type: Account),
    ApiResponse(status: 201, type: Kept),
  ],
)
Future<Object?> all(Object? request) async => null;
