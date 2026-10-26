# Annotation and DTO Recipes

Annotate top-level functions. With axle 0.3.0 you can also annotate methods of
classes and mixins, and top-level variables that hold a closure. A closure passed
inline to a router cannot carry annotation metadata. Methods default to the
operation id `Class_method`.

## Route with parameters, body, and errors

```dart
const userPath = '/users/:id';

@ApiRoute(
  method: ApiMethod.patch,
  path: userPath,
  summary: 'Update a user',
  description: 'Updates profile fields. Omitted fields remain unchanged.',
  tags: ['Users'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'User id.'),
  ],
  headerParams: [
    ApiHeaderParam(
      'If-Match',
      type: String,
      description: 'Optimistic concurrency token.',
    ),
  ],
  body: ApiBody(UpdateUserDto),
  security: [ApiSecurityRequirement(['bearerAuth'])],
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse.badRequest(ApiError),
    ApiResponse.notFound(ApiError),
    ApiResponse(
      status: 409,
      type: ApiError,
      description: 'The user changed since If-Match was issued.',
    ),
  ],
)
Future<Result> updateUser(Request request) async { ... }
```

The `path` must match the framework route. Derive both from the same constant.
For Shelf, use the router's `<id>` syntax in that constant; axle normalizes it
to `{id}` for the OpenAPI document.

## Query, cookie, and constraints

```dart
@ApiRoute(
  method: ApiMethod.get,
  path: '/users',
  queryParams: [
    ApiQueryParam(
      'limit',
      type: int,
      minimum: 1,
      maximum: 100,
      defaultValue: 20,
      description: 'Maximum users returned.',
    ),
    ApiQueryParam(
      'status',
      type: String,
      enumValues: ['active', 'invited', 'disabled'],
      description: 'Filter by account status.',
    ),
  ],
  cookieParams: [
    ApiCookieParam('session', type: String, description: 'Optional session id.'),
  ],
  responses: [ApiResponse.ok(List<UserDto>)],
)
Future<Result> listUsers(Request request) async { ... }
```

Constraints should mirror runtime validation. If the handler rejects
`limit > 100`, the schema should say `maximum: 100`.

## Response headers and multiple media types

The convenience constructors (`ApiResponse.ok`, `created`, etc.) cover common
JSON responses. Use the main constructor when adding headers or multiple media
types:

```dart
ApiResponse(
  status: 200,
  description: 'User details.',
  type: UserDto,
  contentTypes: ['application/json', 'application/vnd.example+json'],
  headers: [
    ApiResponseHeader(
      'ETag',
      type: String,
      description: 'Entity version.',
    ),
    ApiResponseHeader(
      'X-RateLimit-Remaining',
      type: int,
      description: 'Requests remaining in the current window.',
    ),
  ],
)
```

Only list media types the server can actually produce. Content negotiation
should have a corresponding handler behavior.

## Multipart upload

```dart
@ApiSchema(description: 'A multipart CSV import.')
class ImportDto {
  @ApiProperty(format: 'binary', description: 'The CSV file.')
  final Uint8List file;

  const ImportDto(this.file);
}

@ApiRoute(
  method: ApiMethod.post,
  path: '/users/import',
  body: ApiBody(ImportDto, contentTypes: ['multipart/form-data']),
  security: [ApiSecurityRequirement(['bearerAuth'])],
  responses: [
    ApiResponse.created(ImportResult),
    ApiResponse.badRequest(ApiError),
  ],
)
Future<Result> importUsers(Request request) async { ... }
```

`Uint8List` without the override maps to `string`/`byte`, which is not the same
as a multipart file part.

## Explicit oneOf / discriminator

```dart
@ApiSchema(
  description: 'A user activity event.',
  oneOf: [UserCreatedEvent, UserDisabledEvent],
  discriminator: ApiDiscriminator(
    'kind',
    mapping: {
      'created': 'UserCreatedEvent',
      'disabled': 'UserDisabledEvent',
    },
  ),
)
sealed class UserEvent {}

@ApiSchema()
class UserCreatedEvent extends UserEvent {
  @ApiProperty(required: true)
  final String kind = 'created';

  final int userId;
  final String email;

  const UserCreatedEvent({required this.userId, required this.email});
}

@ApiSchema()
class UserDisabledEvent extends UserEvent {
  @ApiProperty(required: true)
  final String kind = 'disabled';

  final int userId;

  const UserDisabledEvent({required this.userId});
}
```

The discriminator mapping values are schema names. axle normalizes them to
`#/components/schemas/...` references in the emitted document.

## Security requirements

Define schemes in `axle.yaml` first.

```dart
// One required scheme.
security: [ApiSecurityRequirement(['bearerAuth'])]

// Alternative schemes (OR).
security: [
  ApiSecurityRequirement(['bearerAuth']),
  ApiSecurityRequirement(['apiKey']),
]

// Multiple schemes in one requirement (AND).
security: [ApiSecurityRequirement(['bearerAuth', 'apiKey'])]

// OAuth2 scopes.
security: [
  ApiSecurityRequirement(
    ['oauth'],
    scopes: {
      'oauth': ['read', 'write'],
    },
  ),
]

// Public operation, overriding a global default.
security: [],
```

The adapter or application middleware must enforce the requirements. axle
validates references and emits metadata; it does not check tokens.

## DTO conventions

```dart
@ApiSchema(description: 'A project member.')
class MemberDto {
  /// Stable member id.
  @ApiProperty(example: 12, minimum: 1)
  final int id;

  /// Member email address.
  @ApiProperty(format: 'email', example: 'ada@example.com')
  final String email;

  /// Role in the project.
  @ApiProperty(enumValues: ['owner', 'editor', 'viewer'])
  final String role;

  /// Internal moderation flag; not part of the public contract.
  @ApiProperty(ignore: true)
  final bool flagged;

  const MemberDto({
    required this.id,
    required this.email,
    required this.role,
    required this.flagged,
  });
}
```

- Use field doc comments for contract descriptions.
- Add examples only when they are realistic and non-sensitive.
- Use nullable field types for optional data; use `required: false` only when
  the wire contract intentionally differs from Dart nullability.
- Use `@JsonSerializable(fieldRename: FieldRename.snake)` on the class, or
  `@ApiProperty(name: 'snake_case')` / `@JsonKey(name: ...)` per field, for wire
  names.
- Prefer explicit DTOs over returning `Map<String, dynamic>`; maps become
  unconstrained objects.

## What axle does not infer

- Automatic `allOf`/`anyOf` composition (use `@ApiSchema(allOf: ...)`).
- Generic sealed classes (list the subtypes with `@ApiSchema(oneOf: ...)`).
- Records and function types.
- Non-string `@JsonValue` and project-wide `build.yaml` `json_serializable`
  options (class-level `fieldRename`, `@JsonEnum` and string `@JsonValue` are
  read).
- Arbitrary OpenAPI `x-` extensions.

Model those cases explicitly or keep the schema simple rather than emitting a
spec that does not match runtime behavior.

## Common mistakes

- Putting `@ApiRoute` on a closure passed inline to a router.
- Using a nullable type literal in `type: int?`; parameter types use `int` and
  nullability is expressed by `required`.
- Forgetting to add a security scheme to `axle.yaml` before referencing it.
- Adding response headers with `ApiResponse.ok`; use the main constructor.
- Declaring `multipart/form-data` but mapping the file as `byte` instead of
  `binary`.
- Hand-editing `openapi.json`, `openapi.yaml`, or `openapi.g.dart`.
