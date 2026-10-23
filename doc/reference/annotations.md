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
| `body` | `ApiBody(type: ...)` — JSON request body |
| `responses` | `ApiResponse(status: ..., type: ..., nullable: ...)` and conveniences (`ok`, `created`, `noContent`, `badRequest`, `notFound`, `internalServerError`) |
| `ignore` | Hides the handler (e.g. wildcard routes `*` / `/**` that OpenAPI cannot represent) |

Repeated annotations are allowed; set a unique `operationId` per annotation.

## `@ApiSchema` / `@ApiProperty`

| Annotation | Fields |
| --- | --- |
| `@ApiSchema` (on classes) | `name`, `description`, `ignore` — force-include an unreferenced model or override metadata |
| `@ApiProperty` (on fields) | `name`, `description`, `example`, `required`, `ignore` |

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
| `Uint8List`, `ByteData` | `string` / `byte` |
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
`json_serializable` field rename rules, polymorphic/sealed-class schemas, and
`oneOf` / `allOf` / `discriminator` generation from class hierarchies.
