// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Person _$PersonFromJson(Map<String, dynamic> json) => _Person(
  name: json['name'] as String,
  age: (json['age'] as num?)?.toInt(),
  role: json['role'] as String? ?? 'guest',
  email: json['e_mail'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$PersonToJson(_Person instance) => <String, dynamic>{
  'name': instance.name,
  'age': instance.age,
  'role': instance.role,
  'e_mail': instance.email,
  'tags': instance.tags,
};

Circle _$CircleFromJson(Map<String, dynamic> json) =>
    Circle((json['radius'] as num).toDouble(), $type: json['type'] as String?);

Map<String, dynamic> _$CircleToJson(Circle instance) => <String, dynamic>{
  'radius': instance.radius,
  'type': instance.$type,
};

Square _$SquareFromJson(Map<String, dynamic> json) => Square(
  side: (json['side'] as num).toDouble(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SquareToJson(Square instance) => <String, dynamic>{
  'side': instance.side,
  'type': instance.$type,
};

Polygon _$PolygonFromJson(Map<String, dynamic> json) => Polygon(
  sides: (json['sides'] as num).toInt(),
  regular: json['regular'] as bool? ?? false,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$PolygonToJson(Polygon instance) => <String, dynamic>{
  'sides': instance.sides,
  'regular': instance.regular,
  'type': instance.$type,
};
