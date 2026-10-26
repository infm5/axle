import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AccountStatus { activeUser, pendingReview }

class EpochConverter extends JsonConverter<DateTime, int> {
  const EpochConverter();
  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);
  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.snake)
class Profile {
  Profile({
    required this.userId,
    required this.status,
    required this.joinedAt,
    this.keepsName,
  });

  final int userId;
  final AccountStatus status;

  @EpochConverter()
  final DateTime joinedAt;

  @JsonKey(name: 'KeepsName')
  final String? keepsName;
}
