import 'package:axle_core/axle_core.dart';

@ApiRoute(method: ApiMethod.get, path: '/duplicate')
Future<Object?> first(Object? request) async => null;

@ApiRoute(method: ApiMethod.get, path: '/duplicate')
Future<Object?> second(Object? request) async => null;
