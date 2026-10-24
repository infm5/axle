# Annotations & DTO Mapping Reference

## Naming defaults

| Concern | Default | Override |
| --- | --- | --- |
| Schema name | Class name | `@ApiSchema(name:)` |
| Operation ID | Handler function name | `@ApiRoute(operationId:)` |
| JSON property name | Dart field name | `@ApiProperty(name:)` → `@JsonKey(name:)` → field name |

Overrides are optional and should be used only for stable public contracts.

## `@ApiRoute` fields

| Field | Meaning |
| --- | --- |
| `method` | `ApiMethod` (`get`, `post`, `put`, `patch`, `delete`, `head`, `options`, `trace`) |
| `path` | Relic/Serverpod or OpenAPI path syntax |
| `summary` / `description` | Operation documentation |
| `operationId` | Defaults to the handler function name |
| `tags` | Operation-local tags |
| `deprecated` | Marks the operation deprecated |
| `pathParams` | `ApiPathParam(name, type: ...)` |
| `queryParams` | `ApiQueryParam(name, type: ..., required: ...)` |
| `headerParams` | `ApiHeaderParam(name, type: ..., required: ...)` |
| `cookieParams` | `ApiCookieParam(name, type: ..., required: ...)` |
| `body` | `ApiBody(type: ..., contentTypes: [...])` |
| `responses` | `ApiResponse(status: ..., type: ..., headers: ..., contentTypes: ...)` |
| `security` | List of `ApiSecurityRequirement`; `null` inherits the document default, `[]` makes the operation public |
| `ignore` | Hides the handler (e.g. wildcard routes `*` / `/**` that OpenAPI cannot represent) |

Repeated annotations are allowed; set a unique `operationId` per annotation.

`ApiResponse.ok`, `created`, `noContent`, `badRequest`, `notFound`, and
`internalServerError` are shortcuts for the common statuses. Use the main
`ApiResponse` constructor when you need response headers or multiple media types:

```dart
ApiResponse(
  status: 200,
  type: UserDto,
  contentTypes: ['application/json', 'application/problem+json'],
  headers: [
    ApiResponseHeader('X-RateLimit', type: int),
  ],
)
```

## Parameter constraints

`ApiPathParam`, `ApiQueryParam`, `ApiHeaderParam`, `ApiCookieParam`, and
`@ApiProperty` accept validation metadata:

| Field | Meaning |
| --- | --- |
| `format` | JSON Schema format, such as `date-time` or `binary` |
| `enumValues` | Allowed values |
| `minimum` / `maximum` | Inclusive numeric bounds |
| `minLength` / `maxLength` | String length bounds |
| `pattern` | Regular expression |

## `@ApiSchema` / `@ApiProperty`

| Annotation | Fields |
| --- | --- |
| `@ApiSchema` (on classes) | `name`, `description`, `oneOf`, `discriminator`, `ignore` |
| `@ApiDiscriminator` | `propertyName`, optional `mapping` |
| `@ApiProperty` (on fields) | `name`, `description`, `example`, `required`, `format`, `enumValues`, `minimum`, `maximum`, `minLength`, `maxLength`, `pattern`, `ignore` |

### `oneOf` composition

Compose a schema from concrete classes and add a discriminator explicitly:

```dart
@ApiSchema(
  oneOf: [CatDto, DogDto],
  discriminator: ApiDiscriminator(
    'kind',
    mapping: {'cat': 'CatDto', 'dog': 'DogDto'},
  ),
)
sealed class PetDto {}

@ApiSchema()
class CatDto extends PetDto {
  final String kind = 'cat';
  final String name;

  const CatDto(this.name);
}
```

The generated `PetDto` component is a `oneOf` with a discriminator. Automatic
inference from sealed class hierarchies is not performed; declare it explicitly.

## Security

Schemes are defined once in `axle.yaml`, then referenced from routes:

```dart
@ApiRoute(
  method: ApiMethod.get,
  path: '/me',
  security: [ApiSecurityRequirement(['bearerAuth'])],
  responses: [ApiResponse.ok(UserDto)],
)
```

For OAuth2 scopes:

```dart
ApiSecurityRequirement(
  ['oauth'],
  scopes: {
    'oauth': ['read', 'write'],
  },
)
```

Multiple requirements are alternatives (OR); schemes inside one requirement must
all be satisfied (AND). `security: []` marks one operation public. The generator
validates references against `security.schemes` in `axle.yaml`. Enforcement is
application-owned.

## Request bodies and uploads

`ApiBody` accepts one or more media types:

```dart
ApiBody(
  UploadDto,
  contentTypes: ['multipart/form-data'],
)
```

`Uint8List` and `ByteData` map to `string`/`byte` by default. For multipart file
parts, override the property format to `binary`:

```dart
@ApiSchema()
class UploadDto {
  @ApiProperty(format: 'binary')
  final Uint8List file;

  const UploadDto(this.file);
}
```

## Dart → JSON Schema mapping

| Dart | JSON Schema |
| --- | --- |
| `int` | `integer` |
| `double`, `num` | `number` |
| `bool` | `boolean` |
| `String` | `string` |
| `DateTime` | `string` / `date-time` |
| `Uri` | `string` / `uri` |
| `Duration` | `string` / `duration` |
| `BigInt` | `integer` / `int64` |
| `Uint8List`, `ByteData` | `string` / `byte` (use `format: 'binary'` for uploads) |
| `List<T>`, `Set<T>`, `Iterable<T>` | `array` with `items` |
| `Map<String, T>` | `object` with `additionalProperties` |
| enum | `string` with enum values |
| class | `$ref` to a component schema |
| `dynamic`, `Object` | unconstrained schema |
| nullable type | `type: [..., "null"]` or `anyOf` for refs |

## Property rules

- Public instance fields only; private and static fields are skipped.
- Inherited fields are included.
- Fields with `@ApiProperty(ignore: true)` are skipped.
- Fields with both `includeToJson: false` and `includeFromJson: false` are skipped.
- Non-nullable fields are required unless `@ApiProperty(required: false)` or a
  `JsonKey.defaultValue` says otherwise.
- Doc comments become property descriptions unless overridden.
- `@JsonKey(name: ...)` is read when the project depends on `json_annotation`.
- Duplicate JSON property names are errors.

## Unsupported (documented limitations, not silent guesses)

Generic DTO classes, type parameters in fields, records, function types, mixins
as DTO types, custom `JsonValue` / `JsonEnum` serialization, global
`json_serializable` field rename rules, automatic `allOf`/`anyOf` inference,
automatic polymorphic inference without `@ApiSchema(oneOf: ...)`, callbacks,
webhooks, links, and arbitrary `x-` extensions.
