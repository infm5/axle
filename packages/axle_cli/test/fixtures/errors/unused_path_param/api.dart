import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  pathParams: [ApiPathParam('other', type: int)],
)
Future<Object?> user(Object? request) async => null;
