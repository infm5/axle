import 'package:axle_core/axle_core.dart';

@ApiRoute(
  method: ApiMethod.get,
  path: '/bad',
  queryParams: [
    ApiQueryParam(
      'x',
      type: String,
      example: 'a',
      examples: {'b': ApiExample('b')},
    ),
  ],
)
Future<Object?> bad(Object? request) async => null;
