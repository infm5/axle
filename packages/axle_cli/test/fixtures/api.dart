import 'package:axle_core/axle_core.dart';
import 'package:json_annotation/json_annotation.dart';

enum Role { admin, member }

@ApiSchema(description: 'A user returned by the API.')
class UserDto {
  @ApiProperty(description: 'The numeric user id.')
  final int id;

  @ApiProperty(name: 'display_name', description: 'The public display name.')
  final String name;

  final Role role;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  final List<String> tags;

  final Map<String, int> scores;

  final AddressDto? address;

  const UserDto({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    this.tags = const [],
    this.scores = const {},
    this.address,
  });
}

class AddressDto {
  /// The city name.
  final String city;

  final String? country;

  const AddressDto({required this.city, this.country});
}

class CreateUserDto {
  final String name;

  @ApiProperty(required: false)
  final Role role;

  const CreateUserDto({required this.name, this.role = Role.member});
}

@ApiSchema(description: 'A health check response.')
class HealthDto {
  final bool ok;

  const HealthDto({required this.ok});
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  summary: 'Get a user',
  tags: ['Users'],
  pathParams: [ApiPathParam('id', type: int, description: 'The user id.')],
  responses: [ApiResponse.ok(UserDto), ApiResponse.notFound()],
)
Future<Object?> getUser(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.post,
  path: '/users',
  summary: 'Create a user',
  tags: ['Users'],
  body: ApiBody(CreateUserDto),
  responses: [ApiResponse.created(UserDto)],
)
Future<Object?> createUser(Object? request) async => null;

@ApiRoute(
  method: ApiMethod.get,
  path: '/users',
  summary: 'List users',
  tags: ['Users'],
  queryParams: [
    ApiQueryParam(
      'limit',
      type: int,
      description: 'Maximum number of users.',
      defaultValue: 20,
    ),
    ApiQueryParam('role', type: Role),
  ],
  responses: [ApiResponse.ok(List<UserDto>)],
)
Future<Object?> listUsers(Object? request) async => null;
