import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

/// The class itself asks for it; there is no build.yaml.
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
class OnlyKeyed {
  OnlyKeyed(this.userName, this.keyedName);
  final String userName;
  @JsonKey()
  final String keyedName;
}

@JsonSerializable(createFactory: false)
class Everything {
  Everything(this.userName, this.keyedName);
  final String userName;
  @JsonKey()
  final String keyedName;
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/all',
  responses: [
    ApiResponse(status: 200, type: OnlyKeyed),
    ApiResponse(status: 201, type: Everything),
  ],
)
Future<Object?> all(Object? request) async => null;
