import 'package:axle_core/axle_core.dart';

class TodoRoutes {
  @ApiRoute(method: ApiMethod.get, path: '/todos')
  Future<Object?> list(Object? request) async => null;

  @ApiRoute(method: ApiMethod.get, path: '/todos/:id')
  static Future<Object?> get(Object? request) async => null;
}

class NoteRoutes {
  @ApiRoute(method: ApiMethod.get, path: '/notes')
  Future<Object?> list(Object? request) async => null;
}

mixin HealthRoutes {
  @ApiRoute(method: ApiMethod.get, path: '/health')
  Future<Object?> health(Object? request) async => null;
}

@ApiRoute(method: ApiMethod.get, path: '/ping', operationId: 'ping')
final pingHandler = (Object? request) async => null;

@ApiRoute(method: ApiMethod.get, path: '/top')
Future<Object?> top(Object? request) async => null;
