import 'package:axle_core/axle_core.dart';

@ApiRoute(method: ApiMethod.get, path: '/one', operationId: 'same')
Future<Object?> one(Object? request) async => null;

@ApiRoute(method: ApiMethod.post, path: '/two', operationId: 'same')
Future<Object?> two(Object? request) async => null;
