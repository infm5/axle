import 'dart:async';
import 'dart:typed_data';

import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

@ApiSchema(name: 'RenamedDto', description: 'A renamed schema.')
class OriginalDto {
  late final String value;
}

@ApiSchema(ignore: true)
class HiddenDto {
  late final String hidden;
}

@ApiSchema()
class NodeDto {
  late final NodeDto? next;
}

@ApiSchema()
class BaseDto {
  late final String base;
}

@ApiSchema()
class ChildDto extends BaseDto {
  late final int child;
}

@ApiSchema(name: '123 weird-name')
class WeirdNameDto {
  late final String value;
}

enum EdgeEnum { one, two }

@ApiSchema()
class ExampleValuesDto {
  @ApiProperty(example: 1.5)
  late final double doubleValue;

  @ApiProperty(example: [1, 2])
  late final List<int> listValue;

  @ApiProperty(example: {1, 2})
  late final Set<int> setValue;

  @ApiProperty(example: {'a': 1})
  late final Map<String, int> mapValue;

  @ApiProperty(example: EdgeEnum.two)
  late final EdgeEnum enumValue;
}

@ApiSchema()
class EdgeTypesDto {
  late final Uri uri;
  late final Duration duration;
  late final BigInt big;
  late final Uint8List bytes;
  late final ByteData bytesData;
  late final dynamic anything;
  late final Object object;
  late final Never neverValue;
  late final Null nothing;
  late final List rawList;
  late final Map rawMap;
  late final Map<int, String> intKeys;
  late final Set<String> tags;
  late final Iterable<int> numbers;
  late final Future<String> future;
  late final FutureOr<int> futureOr;
  late final String? optional;

  @ApiProperty(example: 'example')
  late final String withExample;

  @JsonKey(defaultValue: 'fallback')
  late final String withDefault;

  @ApiProperty(ignore: true)
  late final String ignored;

  @JsonKey(includeToJson: false, includeFromJson: false)
  late final String jsonIgnored;

  @ApiProperty(required: true)
  late final String? forcedRequired;

  static const String staticField = 'static';
  final String _private = 'private';

  String get privateValue => _private;
}
