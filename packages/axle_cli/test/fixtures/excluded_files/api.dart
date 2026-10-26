import 'package:axle_core/axle_core.dart';

part 'api.mapper.dart';

class Thing {
  const Thing(this.name);
  final String name;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/things',
  responses: [ApiResponse.ok(Thing)],
)
Future<Object?> things(Object? request) async => null;
