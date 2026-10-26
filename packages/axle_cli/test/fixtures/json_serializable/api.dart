import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

const profilePath = '/profiles/:profileId';

@JsonEnum(fieldRename: FieldRename.snake)
enum AccountStatus { activeUser, pendingReview }

enum Tier {
  @JsonValue('free-tier')
  free,
  paid,
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.snake)
class SnakeProfile {
  SnakeProfile({
    required this.userId,
    required this.displayName,
    required this.status,
    required this.tier,
    required this.keepsName,
    required this.apiOverride,
  });

  final int userId;
  final String displayName;
  final AccountStatus status;
  final Tier tier;

  @JsonKey(name: 'KeepsName')
  final String keepsName;

  @ApiProperty(name: 'api-override')
  final String apiOverride;
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.kebab)
class KebabProfile {
  KebabProfile({required this.userId});
  final int userId;
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.pascal)
class PascalProfile {
  PascalProfile({required this.userId});
  final int userId;
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.screamingSnake)
class ScreamingProfile {
  ScreamingProfile({required this.userId});
  final int userId;
}

@ApiSchema()
@JsonSerializable()
class PlainProfile {
  PlainProfile({required this.userId});
  final int userId;
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.snake)
class DerivedProfile extends PlainProfile {
  DerivedProfile({required super.userId, required this.createdAt});
  final String createdAt;
}

@ApiRoute(
  method: ApiMethod.get,
  path: profilePath,
  pathParams: [ApiPathParam('profileId', type: int)],
  responses: [ApiResponse.ok(SnakeProfile)],
)
Future<Object?> getProfile(Object? request) async => null;
