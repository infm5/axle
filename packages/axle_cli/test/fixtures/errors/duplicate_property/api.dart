import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

@ApiSchema()
class DuplicateDto {
  @ApiProperty(name: 'same')
  late final String first;

  @JsonKey(name: 'same')
  late final String second;
}
