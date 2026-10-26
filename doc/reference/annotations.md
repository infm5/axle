# Annotations and DTO Mapping Reference

This page lists every annotation axle reads and how Dart types become schemas.
Items marked <Badge type="tip" text="0.3.0" /> are not in the published `0.2.0`
packages yet; see the [roadmap](/guide/roadmap#_0-3-0).

## Naming defaults

| Concern | Default | Override |
| --- | --- | --- |
| Schema name | Class name | `@ApiSchema(name:)` |
| Generic schema name | Class name plus type arguments (`Page_UserDto`) | `@ApiSchema(name:)` replaces the class name part |
| Operation ID | Function name, or `Class_method` for methods | `@ApiRoute(operationId:)` |
| JSON property name | Dart field name | [See precedence](/models/#how-a-property-is-named) |

Overrides are optional and should be used only for stable public contracts.

## Routes

### `@ApiRoute` fields

| Field | Meaning |
| --- | --- |
| `method` | `ApiMethod` (`get`, `post`, `put`, `patch`, `delete`, `head`, `options`, `trace`) |
| `path` | Relic, Shelf, or Serverpod syntax, or OpenAPI syntax |
| `summary` / `description` | Operation documentation |
| `operationId` | Defaults to the function name, or `Class_method` for methods |
| `tags` | Operation-local tags |
| `deprecated` | Marks the operation deprecated |
| `pathParams` | `ApiPathParam(name, type: ...)` |
| `queryParams` | `ApiQueryParam(name, type: ..., required: ...)` |
| `headerParams` | `ApiHeaderParam(name, type: ..., required: ...)` |
| `cookieParams` | `ApiCookieParam(name, type: ..., required: ...)` |
| `body` | `ApiBody(type, contentTypes: [...])` |
| `bodies` <Badge type="tip" text="0.3.0" /> | More `ApiBody`s, for media types that carry a different schema; see [Several media types](#several-media-types) |
| `responses` | A list of `ApiResponse`; see [Responses](#responses) |
| `security` | List of `ApiSecurityRequirement`; `null` inherits the document default, `[]` makes the operation public |
| `ignore` | Hides the handler, for example wildcard routes (`*`, `/**`) that OpenAPI cannot represent |

Repeated annotations are allowed; set a unique `operationId` on each. An empty
`responses` list emits `200 OK` without a body.

### Where routes can live <Badge type="tip" text="0.3.0" />

`@ApiRoute` works on:

- top-level functions;
- top-level variables that hold a closure;
- methods, static or instance, of classes and mixins.

A closure passed inline to a router, such as `app.get('/x', (request) {...})`,
cannot carry an annotation. Before 0.3.0 only top-level functions were read.

The path in the annotation is separate from the path you register with the
router, so the two can drift. Use one constant for both, and
[test that every documented path is served](/guide/keeping-paths-in-sync):

```dart
const todoPath = '/todos/:id';

@ApiRoute(method: ApiMethod.get, path: todoPath, ...)
Future<Response> getTodo(Request request) async { ... }

router.get(todoPath, getTodo);
```

## Parameters

### Constraints

`ApiPathParam`, `ApiQueryParam`, `ApiHeaderParam`, `ApiCookieParam`, and
`@ApiProperty` accept validation metadata:

| Field | Meaning |
| --- | --- |
| `format` | JSON Schema format, such as `date-time` or `binary` |
| `enumValues` | Allowed values |
| `minimum` / `maximum` | Inclusive numeric bounds |
| `minLength` / `maxLength` | String length bounds |
| `pattern` | Regular expression |

Parameters take a Dart `Type` literal (`type: int`), never a nullable one.

On a list (`List<int>`, `List<Uint8List>`), the constraint describes each item,
because JSON Schema has no such keywords for arrays. `@ApiProperty(minimum: 1)`
on a `List<int>` means every id is at least 1. <Badge type="tip" text="0.3.0" />

### Style and explode <Badge type="tip" text="0.3.0" />

All four parameter annotations take `style:` and `explode:`. They matter for
arrays and objects:

```dart
ApiQueryParam('ids', type: List<int>, explode: false),            // ?ids=1,2,3
ApiQueryParam('tags', type: List<String>),                        // ?tags=a&tags=b
ApiQueryParam('sort', type: List<String>, style: ApiParameterStyle.pipeDelimited),
ApiQueryParam('filter', type: Filter, style: ApiParameterStyle.deepObject),
```

| Location | Allowed styles | Default |
| --- | --- | --- |
| path | `matrix`, `label`, `simple` | `simple` |
| header | `simple` | `simple` |
| query | `form`, `spaceDelimited`, `pipeDelimited`, `deepObject` | `form` |
| cookie | `form` | `form` |

`explode` defaults to `true` for `form` and `false` for every other style. axle
rejects a style that is not allowed for the location, and leaves out any value
that equals the default, so the document stays small.

### Named examples <Badge type="tip" text="0.3.0" />

`example:` sets one value. `examples:` sets several, each with an optional
summary and description:

```dart
ApiQueryParam(
  'q',
  type: String,
  examples: {
    'word': ApiExample('cat', summary: 'One word'),
    'phrase': ApiExample('black cat'),
  },
)

ApiBody(
  Item,
  examples: {
    'minimal': ApiExample({'id': 1, 'name': 'Lamp'}),
    'remote': ApiExample.external('https://example.com/item.json'),
  },
)
```

Parameters, `ApiBody`, and `ApiResponse` accept `examples`. Setting both
`example` and `examples` on one element is an error, because OpenAPI does not
allow it. Example values must be compile-time constants.

## Request bodies and uploads

`ApiBody` accepts one or more media types:

```dart
ApiBody(
  UploadDto,
  contentTypes: ['multipart/form-data'],
)
```

`Uint8List` and `ByteData` map to `string` / `byte` by default. For multipart
file parts, override the property format to `binary`:

```dart
@ApiSchema()
class UploadDto {
  @ApiProperty(format: 'binary')
  final Uint8List file;

  const UploadDto(this.file);
}
```

## Responses

| Constructor | Key |
| --- | --- |
| `ApiResponse.ok`, `created`, `noContent` | `200`, `201`, `204` |
| `ApiResponse.badRequest`, `notFound` | `400`, `404` |
| `ApiResponse.unauthorized`, `forbidden` <Badge type="tip" text="0.3.0" /> | `401`, `403` |
| `ApiResponse.conflict`, `unprocessableEntity`, `tooManyRequests` <Badge type="tip" text="0.3.0" /> | `409`, `422`, `429` |
| `ApiResponse.internalServerError` | `500` |
| `ApiResponse(status: ...)` | Any status from 100 to 599 |
| `ApiResponse.range(4)` <Badge type="tip" text="0.3.0" /> | `4XX`. The argument is the first digit, 1 to 5. |
| `ApiResponse.defaultResponse()` <Badge type="tip" text="0.3.0" /> | `default`: every status no other response declares |

`range` and `defaultResponse` take their options by name (`type:`, `description:`,
`headers:`, `contentTypes:`), so they can describe `application/problem+json`:

```dart
ApiResponse.range(
  4,
  type: Problem,
  contentTypes: ['application/problem+json'],
),
```

The shortcuts take an optional body type, description, and example. Use the main
constructor when you need response headers or several media types:

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

Within an operation, an exact status beats its range, and a range beats
`default`. The document lists exact statuses first, then ranges, then `default`.
A range or `default` response without a description gets a generic one (`Client
error`, `Unexpected error`).

Shared error lists do not need a feature of their own. Annotation arguments are
constants, so a const list can be spread into any operation:

```dart
const protectedErrors = [
  ApiResponse.unauthorized(ApiError),
  ApiResponse.forbidden(ApiError),
  ApiResponse.tooManyRequests(ApiError),
];

@ApiRoute(
  method: ApiMethod.get,
  path: '/items',
  responses: [ApiResponse.ok(Item), ...protectedErrors],
)
```

### Several media types <Badge type="tip" text="0.3.0" />

A route can return, or accept, the same thing in several formats. When every
format shares one schema, list them in `contentTypes`. When they do not, declare
the status again with the other media type, and axle merges the responses:

```dart
responses: [
  ApiResponse(status: 200, type: Report),                         // JSON
  ApiResponse(
    status: 200,
    type: String,
    contentTypes: ['text/csv', 'text/tab-separated-values'],
    headers: [ApiResponseHeader('Content-Disposition', type: String)],
  ),
],
```

The result is one `200` with `application/json`, `text/csv`, and
`text/tab-separated-values` content, each with its own schema. Headers from all
the entries are combined, and the first non-empty description wins. Declaring a
status again without adding a new media type is a duplicate error.

Request bodies work the same way through `bodies`:

```dart
body: ApiBody(MergePatch, contentTypes: ['application/merge-patch+json']),
bodies: [
  ApiBody(
    List<PatchOperation>,
    contentTypes: ['application/json-patch+json'],
  ),
],
```

A media type may appear only once across `body` and `bodies`.

### Binary data <Badge type="tip" text="0.3.0" />

`Uint8List` and `ByteData` are bytes. Inside JSON they travel as base64 text
(`format: byte`). Under any other media type they are the raw body, which OpenAPI
calls `format: binary`. axle picks by media type:

```dart
ApiResponse(status: 200, type: Uint8List, contentTypes: ['image/png']),            // binary
ApiResponse(status: 201, type: Uint8List),                                         // base64 in JSON
ApiBody(Uint8List, contentTypes: ['application/octet-stream']),                    // binary
```

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

## Schemas

### `@ApiSchema` and `@ApiProperty`

| Annotation | Fields |
| --- | --- |
| `@ApiSchema` (on classes) | `name`, `description`, `oneOf`, `allOf` <Badge type="tip" text="0.3.0" />, `anyOf` <Badge type="tip" text="0.3.0" />, `discriminator`, `ignore` |
| `@ApiDiscriminator` | `propertyName`, optional `mapping` |
| `@ApiProperty` (on fields) | `name`, `type` <Badge type="tip" text="0.3.0" />, `description`, `example`, `required`, `format`, `enumValues`, `minimum`, `maximum`, `minLength`, `maxLength`, `pattern`, `ignore` |

Referenced classes are always emitted. `@ApiSchema` is only needed to
force-include an unreferenced class or to override metadata.

### Dart to JSON Schema

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

### Property rules

- Public instance fields only; private and static fields are skipped.
- Inherited fields are included.
- Fields with `@ApiProperty(ignore: true)` are skipped.
- Fields with both `includeToJson: false` and `includeFromJson: false` are skipped.
- A property is required when its Dart type is not nullable and it has no
  default. `@ApiProperty(required:)` overrides this.
- Doc comments become property descriptions unless overridden.
- Duplicate JSON property names are errors.

Names, defaults, and converters depend on your serialization package. See
[Models and serialization](/models/).

### Generic DTOs <Badge type="tip" text="0.3.0" />

Each instantiation becomes its own schema, named after the type arguments:
`Page<UserDto>` is `Page_UserDto` and `Envelope<Page<UserDto>>` is
`Envelope_Page_UserDto`. Fields, inherited fields, nested generics, and
self-referencing generics are resolved with the type arguments applied. A
generic class is registered where it is used. `@ApiSchema` on the generic
declaration applies to every instantiation. Before 0.3.0, generic classes were
an error.

### Composition

| Source | Schema |
| --- | --- |
| `sealed class` <Badge type="tip" text="0.3.0" /> | `oneOf` of its direct subtypes, found in the same library. Subtypes marked `@ApiSchema(ignore: true)` are left out. |
| `@ApiSchema(oneOf: [...])` | `oneOf` of the listed types |
| `@ApiSchema(anyOf: [...])` <Badge type="tip" text="0.3.0" /> | `anyOf` of the listed types |
| `@ApiSchema(allOf: [Base])` <Badge type="tip" text="0.3.0" /> | `allOf` of the listed types, followed by an inline object with the fields the class declares itself |

Set only one of `oneOf`, `anyOf`, and `allOf` per class. A `discriminator` goes
with `oneOf`, `anyOf`, or a sealed class, never `allOf`. Generic sealed classes
cannot be expanded automatically; list their subtypes with `oneOf`.

A sealed class without a discriminator produces a warning, because clients
cannot tell the subtypes apart when their JSON overlaps. Declare the
discriminator, and give every member the discriminator property:

```dart
@ApiSchema(
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

The `PetDto` component is a `oneOf` of `CatDto` and `DogDto` with a
discriminator. List the subtypes yourself with `@ApiSchema(oneOf: [...])` when
they live in another library.

### Overriding the JSON type of a property <Badge type="tip" text="0.3.0" />

`@ApiProperty(type: ...)` states what a property is in JSON when a converter
changes it. Nullability still comes from the field. See
[Models and serialization](/models/#how-a-property-s-type-is-chosen).

```dart
@ApiProperty(type: String)
final Money? price;   // sent as a string, still nullable
```

### Serialization packages

axle reads `json_serializable`, `freezed`, and `dart_mappable` annotations. What
each one affects, the precedence rules, and install notes are on the
[Models and serialization](/models/) pages.

## Unsupported

These are documented limits, not silent guesses. axle reports an error or a
warning instead of producing a schema it cannot stand behind.

- Records, function types, and mixins as DTO types.
- Generic sealed classes (list the subtypes with `oneOf`).
- Non-string `@JsonValue`, and `@JsonEnum(valueField:)`.
- Serializer options in `build.yaml` other than `field_rename`, `ignore_unannotated`, `caseStyle`, and `enumCaseStyle`; the rest do not change the JSON.
- freezed `unionValueCase`, and dart_mappable discriminators.
- Inferring `allOf` or `anyOf` from inheritance. They are explicit.
- Callbacks, webhooks, links, and `x-` extensions.
