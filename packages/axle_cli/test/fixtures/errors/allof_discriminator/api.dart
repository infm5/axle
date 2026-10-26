import 'package:axle_core/axle_core.dart';

class Base {}

@ApiSchema(allOf: [Base], discriminator: ApiDiscriminator('kind'))
class Child extends Base {}

@ApiRoute(
  method: ApiMethod.get,
  path: '/child',
  responses: [ApiResponse.ok(Child)],
)
Future<Object?> child(Object? request) async => null;
