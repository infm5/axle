import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false)
class Defaulted {
  Defaulted(this.userName, this.keyedName);
  final String userName;
  @JsonKey()
  final String keyedName;
}

@JsonSerializable(
  createFactory: false,
  fieldRename: FieldRename.none,
  ignoreUnannotated: false,
)
class Overridden {
  Overridden(this.userName, this.keyedName);
  final String userName;
  @JsonKey()
  final String keyedName;
}

@JsonSerializable(createFactory: false, fieldRename: FieldRename.kebab)
class Kebab {
  Kebab(this.userName);
  @JsonKey()
  final String userName;
}

/// Not processed by json_serializable, so no option reaches it.
class Plain {
  Plain(this.userName);
  final String userName;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/all',
  responses: [
    ApiResponse(status: 200, type: Defaulted),
    ApiResponse(status: 201, type: Overridden),
    ApiResponse(status: 202, type: Kebab),
    ApiResponse(status: 203, type: Plain),
  ],
)
Future<Object?> all(Object? request) async => null;
