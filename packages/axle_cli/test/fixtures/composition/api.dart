import 'package:axle_core/axle_core.dart';

@ApiSchema()
class Animal {
  late final String name;
}

@ApiSchema(allOf: [Animal], description: 'A dog.')
class Dog extends Animal {
  late final bool goodBoy;
  late final int? age;
}

@ApiSchema(allOf: [Animal])
class PlainAnimal extends Animal {}

@ApiSchema()
class Phone {
  late final String number;
}

@ApiSchema()
class Email {
  late final String address;
}

@ApiSchema(
  anyOf: [Phone, Email],
  description: 'Any way to reach someone.',
  discriminator: ApiDiscriminator('channel'),
)
class Contact {}

@ApiRoute(
  method: ApiMethod.get,
  path: '/dogs',
  responses: [ApiResponse.ok(Dog), ApiResponse.notFound(PlainAnimal)],
)
Future<Object?> dogs(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/contacts',
  responses: [ApiResponse.ok(Contact)],
)
Future<Object?> contacts(Object? request) async => null;
