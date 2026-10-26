import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.post,
  path: '/twice',
  body: ApiBody(String, contentTypes: ['text/plain']),
  bodies: [
    ApiBody(int, contentTypes: ['text/plain']),
  ],
)
Future<Object?> twice(Object? request) async => null;
