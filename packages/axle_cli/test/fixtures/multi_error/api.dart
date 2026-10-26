import 'package:axle_core/axle_core.dart';

class Holder {
  const Holder(this.pair);
  final (int, int) pair;
}

@ApiRoute(method: ApiMethod.get, path: '/duplicate')
Future<Object?> first(Object? request) async => null;

@ApiRoute(method: ApiMethod.get, path: '/duplicate')
Future<Object?> second(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/items/{id}',
  pathParams: [ApiPathParam('other', type: int)],
)
Future<Object?> third(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/holders',
  responses: [ApiResponse.ok(Holder)],
)
Future<Object?> fourth(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/holders/other',
  responses: [ApiResponse.ok(Holder)],
)
Future<Object?> fifth(Object? request) async => null;
