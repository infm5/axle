# `axle_core`

## What it is

The framework-agnostic contract language: route annotations, the OpenAPI 3.1
document model, JSON Schema helpers, Swagger UI HTML generation, and `AxleDocs`
— the framework-neutral payload every adapter serves. No runtime dependencies;
must never import Relic, Shelf, Serverpod, or Dart Frog.

## Install

Apps usually get core transitively — every adapter re-exports it. Depend on it
directly when building an adapter or using the document model standalone:

```yaml
dependencies:
  axle_core: ^0.1.0
```

```dart
import 'package:axle_core/axle_core.dart';
```

## API

### `@ApiRoute`

One OpenAPI operation per annotation, on **top-level handler functions only**.
Repeat annotations to document several methods on one handler; each needs a
unique `operationId` (the default is the function name, so repeats collide
without explicit IDs).

```dart
@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  summary: 'Get a user',
  description: '...',
  operationId: 'getUser',
  tags: ['Users'],
  deprecated: false,
  pathParams: [ApiPathParam('id', type: int)],
  queryParams: [ApiQueryParam('page', type: int, required: false)],
  headerParams: [ApiHeaderParam('x-trace', type: String, required: false)],
  body: ApiBody(UserInput),
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse.notFound(),
  ],
  ignore: false,
)
```

- `method` is `ApiMethod`: `get`, `post`, `put`, `patch`, `delete`, `head`,
  `options`, `trace`.
- `path` accepts Relic syntax (`/users/:id`) and OpenAPI syntax
  (`/users/{id}`).
- `responses` empty emits `200 OK` with no body.
- `ignore: true` hides the handler — required for wildcard routes (`*`,
  `/**`), which OpenAPI cannot represent.

Parameters carry a Dart `Type` literal (`type: int`), never a nullable type
literal — `int?` is not valid Dart in that position. Nullability is expressed
via `ApiResponse(nullable: true)` or the DTO field type. `ApiQueryParam` also
accepts `defaultValue`. `ApiBody` defaults to `required: true`.

`ApiResponse` constructors and their defaults:

| Constructor | Status | Default description | Body |
| --- | --- | --- | --- |
| `ApiResponse(status:, type:, description:, nullable:, example:)` | explicit | `''` | optional `Type` |
| `.ok([type, description, example])` | 200 | `'OK'` | optional |
| `.created(...)` | 201 | `'Created'` | optional |
| `.noContent([description])` | 204 | `'No Content'` | none — `type` is always null |
| `.badRequest(...)` | 400 | `'Bad Request'` | optional |
| `.notFound(...)` | 404 | `'Not Found'` | optional |
| `.internalServerError(...)` | 500 | `'Internal Server Error'` | optional |

### `@ApiSchema` / `@ApiProperty`

Schemas are inferred from classes referenced by `ApiBody` / `ApiResponse`.
These annotations only override metadata or force-include unreferenced models:

```dart
@ApiSchema(name: 'User', description: 'A user returned by the API.')
class UserDto {
  @ApiProperty(description: 'Stable user id.')
  final int id;

  @ApiProperty(name: 'fullName', required: false, example: 'Ada')
  final String name;

  @ApiProperty(ignore: true)
  final String internalFlag;
}
```

- `@ApiSchema(ignore: true)` skips auto-inclusion, but referenced classes are
  still generated — the document needs them.
- Property name precedence: `@ApiProperty(name:)` → `@JsonKey(name:)` (read
  when the project depends on `json_annotation`) → Dart field name.
- Omitted `required` means: non-nullable fields without a default are required.

### `AxleDocs`

One instance per mounted docs surface. Normalizes paths, resolves the title,
applies the cache policy, renders the UI HTML:

```dart
final docs = AxleDocs(
  spec: axleOpenApiJson,
  specPath: '/openapi.json',
  docsPath: '/docs',
  title: null, // explicit title, else info.title, else 'API Docs'
  swaggerUiUrl: defaultSwaggerUiUrl,
  noCache: true,
);

docs.specJson; // exact generated artifact
docs.specPath; // /openapi.json
docs.docsPath; // /docs
docs.uiHtml;   // standalone Swagger UI HTML
docs.headers;  // {'cache-control': 'no-store'}
```

Rules: paths are trimmed and forced to a leading `/`; empty paths throw;
identical `specPath`/`docsPath` throw. A missing or blank `info.title` (or an
unparseable spec) falls back to `API Docs` — never an exception.

`swaggerUiCssIntegrity` / `swaggerUiBundleIntegrity` override the SRI hashes
(e.g. for a custom CDN); when the default CDN URL is used, the pinned default
hashes apply automatically. Adapter entry points do not surface these fields —
custom-CDN deployments needing SRI should construct `AxleDocs` directly (see
[Building an Adapter](/adapters/building-an-adapter)).

### Document model and `swaggerUiHtml`

`OpenApiDocument`, `OpenApiInfo`, `OpenApiContact`, `OpenApiLicense`,
`OpenApiServer`, `OpenApiComponents`, `OpenApiPathItem`, `OpenApiOperation`,
`OpenApiParameter`, `OpenApiRequestBody`, `OpenApiResponse`,
`OpenApiMediaType`, and `OpenApiSchema` (nullable refs, arrays, maps, enums,
objects, metadata) model OpenAPI 3.1 directly.

```dart
swaggerUiHtml({
  String specUrl = '/openapi.json',
  String title = 'API Docs',
  String swaggerUiUrl = defaultSwaggerUiUrl,
  String? swaggerUiCssIntegrity,
  String? swaggerUiBundleIntegrity,
  bool persistAuthorization = true,
  bool displayRequestDuration = true,
})
```

Defaults: pinned `https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.34.0` with
SRI hashes. Title is HTML-escaped, the spec URL is JSON-encoded with `<`
neutralized, and a trailing slash on the asset base URL is stripped. Local
assets pass `null` integrities. For offline deployments, generate local assets
with `axle gen` and point the adapter at them via `swaggerUiDirectory`.

## Boundaries

- No framework imports, no HTTP types, no file I/O.
- No generation logic — the CLI owns scanning and emitting.
- No auth, validation, or serialization.
- No runtime route discovery.
