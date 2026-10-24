import 'dart:typed_data';

import 'package:axle_core/axle_core.dart';

@ApiSchema(description: 'A response with validation constraints.')
class SecureDto {
  @ApiProperty(
    description: 'A constrained name.',
    minLength: 3,
    maxLength: 20,
    pattern: r'^[a-z]+$',
  )
  final String name;

  @ApiProperty(minimum: 1, maximum: 100, enumValues: [1, 2, 3])
  final int count;

  const SecureDto({required this.name, required this.count});
}

@ApiRoute(
  method: ApiMethod.get,
  path: '/secure/:id',
  summary: 'Read a protected resource',
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, maximum: 999, format: 'int64'),
  ],
  queryParams: [
    ApiQueryParam(
      'state',
      type: String,
      enumValues: ['new', 'done'],
      minLength: 2,
    ),
  ],
  headerParams: [
    ApiHeaderParam(
      'X-Tenant',
      type: String,
      required: true,
      pattern: r'^[a-z0-9-]+$',
    ),
  ],
  cookieParams: [ApiCookieParam('session', type: String, required: true)],
  security: [
    ApiSecurityRequirement(['bearerAuth']),
  ],
  responses: [
    ApiResponse(
      status: 200,
      description: 'OK',
      type: SecureDto,
      contentTypes: ['application/json', 'application/problem+json'],
      headers: [
        ApiResponseHeader(
          'X-RateLimit',
          type: int,
          description: 'Remaining requests.',
          required: true,
        ),
      ],
    ),
  ],
)
Future<void> readSecure(Object? request) async {}

@ApiRoute(
  method: ApiMethod.post,
  path: '/secure',
  summary: 'Create a protected resource',
  body: ApiBody(
    SecureDto,
    contentTypes: ['application/json', 'application/x-www-form-urlencoded'],
  ),
  security: [
    ApiSecurityRequirement(
      ['oauth2'],
      scopes: {
        'oauth2': ['write'],
      },
    ),
  ],
  responses: [ApiResponse.created(SecureDto)],
)
Future<void> createSecure(Object? request) async {}

@ApiSchema(
  oneOf: [CatDto, DogDto],
  discriminator: ApiDiscriminator(
    'kind',
    mapping: {'cat': 'CatDto', 'dog': 'DogDto'},
  ),
)
sealed class PetDto {
  const PetDto();
}

@ApiSchema()
class CatDto extends PetDto {
  @ApiProperty(required: true)
  final String kind = 'cat';
  final String name;

  const CatDto(this.name);
}

@ApiSchema()
class DogDto extends PetDto {
  @ApiProperty(required: true)
  final String kind = 'dog';
  final String name;

  const DogDto(this.name);
}

@ApiSchema()
class UploadDto {
  @ApiProperty(format: 'binary')
  final Uint8List file;

  const UploadDto(this.file);
}

@ApiRoute(
  method: ApiMethod.post,
  path: '/upload',
  summary: 'Upload a file',
  body: ApiBody(UploadDto, contentTypes: ['multipart/form-data']),
  responses: [ApiResponse.created(UploadDto)],
)
Future<void> upload(Object? request) async {}

@ApiRoute(
  method: ApiMethod.get,
  path: '/pet',
  summary: 'Get a pet',
  responses: [ApiResponse.ok(PetDto)],
)
Future<void> getPet(Object? request) async {}

@ApiRoute(
  method: ApiMethod.get,
  path: '/public',
  summary: 'A public endpoint',
  security: [],
  responses: [ApiResponse.ok()],
)
Future<void> publicEndpoint(Object? request) async {}
