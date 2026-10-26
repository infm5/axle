import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class Person with _$Person {
  const factory Person({
    required String name,
    int? age,
    @Default('guest') String role,
    @JsonKey(name: 'e_mail') String? email,
    @Default(<String>[]) List<String> tags,
  }) = _Person;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}

@Freezed(unionKey: 'type')
sealed class Shape with _$Shape {
  const factory Shape.circle(double radius) = Circle;
  @FreezedUnionValue('sq')
  const factory Shape.square({required double side}) = Square;
  const factory Shape.polygon({
    required int sides,
    @Default(false) bool regular,
  }) = Polygon;

  factory Shape.fromJson(Map<String, dynamic> json) => _$ShapeFromJson(json);
}
