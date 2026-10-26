import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/bad',
  queryParams: [
    ApiQueryParam('x', type: String, style: ApiParameterStyle.matrix),
  ],
)
Future<Object?> bad(Object? request) async => null;
