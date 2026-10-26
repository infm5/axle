import 'package:axle_core/axle_core.dart';

sealed class Shape {
  const Shape(this.label);
  final String label;
}

final class Circle extends Shape {
  const Circle(super.label, this.radius);
  final double radius;
}

final class Square extends Shape {
  const Square(super.label, this.side);
  final double side;
}

@ApiSchema(ignore: true)
final class Secret extends Shape {
  const Secret(super.label);
}

@ApiSchema(
  description: 'A pet.',
  discriminator: ApiDiscriminator(
    'kind',
    mapping: {'dog': 'Dog', 'cat': 'Cat'},
  ),
)
sealed class Pet {}

final class Dog extends Pet {
  late final String bark;
}

final class Cat extends Pet {
  late final int lives;
}

sealed class Event {}

sealed class UserEvent extends Event {}

final class UserCreated extends UserEvent {
  late final String id;
}

final class UserDeleted extends UserEvent {
  late final String id;
}

final class SystemEvent extends Event {
  late final String message;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/shapes',
  responses: [ApiResponse.ok(Shape)],
)
Future<Object?> shapes(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/pets',
  responses: [ApiResponse.ok(Pet)],
)
Future<Object?> pets(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/events',
  responses: [ApiResponse.ok(Event)],
)
Future<Object?> events(Object? request) async => null;
