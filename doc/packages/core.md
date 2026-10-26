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
  axle_core: ^0.2.0
```

```dart
import 'package:axle_core/axle_core.dart';
```

## API

### `@ApiRoute`

One OpenAPI operation per annotation. It goes on a top-level function; from
0.3.0 it can also go on a method of a class or mixin, or on a top-level variable
that holds a closure. Repeat annotations to document several methods on one
handler; each needs a unique `operationId`. The default is the function name
(`Class_method` for methods), so repeats collide without explicit IDs.

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
  cookieParams: [ApiCookieParam('session', type: String)],
  body: ApiBody(UserInput, contentTypes: ['application/json']),
  bodies: [], // more ApiBody entries, one schema per media type
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse.notFound(),
  ],
  security: [ApiSecurityRequirement(['bearerAuth'])],
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
accepts `defaultValue`; all parameter classes accept `format`, `enumValues`,
`minimum`, `maximum`, `minLength`, `maxLength`, and `pattern`. `ApiBody` defaults
to `required: true` and `contentTypes: ['application/json']`.

`ApiResponse` constructors and their defaults:

| Constructor | Key | Default description | Body |
| --- | --- | --- | --- |
| `ApiResponse(status:, type:, description:, nullable:, example:, examples:, headers:, contentTypes:)` | explicit status | `''` | optional `Type` |
| `.ok([type, description, example])` | 200 | `'OK'` | optional |
| `.created(...)` | 201 | `'Created'` | optional |
| `.noContent([description])` | 204 | `'No Content'` | none; `type` is always null |
| `.badRequest(...)` | 400 | `'Bad Request'` | optional |
| `.unauthorized(...)` <Badge type="tip" text="0.3.0" /> | 401 | `'Unauthorized'` | optional |
| `.forbidden(...)` <Badge type="tip" text="0.3.0" /> | 403 | `'Forbidden'` | optional |
| `.notFound(...)` | 404 | `'Not Found'` | optional |
| `.conflict(...)` <Badge type="tip" text="0.3.0" /> | 409 | `'Conflict'` | optional |
| `.unprocessableEntity(...)` <Badge type="tip" text="0.3.0" /> | 422 | `'Unprocessable Entity'` | optional |
| `.tooManyRequests(...)` <Badge type="tip" text="0.3.0" /> | 429 | `'Too Many Requests'` | optional |
| `.internalServerError(...)` | 500 | `'Internal Server Error'` | optional |
| `.range(hundreds, {type, description, example, headers, contentTypes, ...})` <Badge type="tip" text="0.3.0" /> | `4XX` for `range(4)` | generic | optional |
| `.defaultResponse({type, description, example, headers, contentTypes, ...})` <Badge type="tip" text="0.3.0" /> | `default` | `'Unexpected error'` | optional |

Parameter annotations also take `style:`, `explode:`, and `examples:`
<Badge type="tip" text="0.3.0" />, and `ApiBody` takes `examples:`. Named examples
use `ApiExample(value)` or `ApiExample.external(url)`. See the
[reference](/reference/annotations).

### `@ApiSchema` / `@ApiProperty`

Schemas are inferred from classes referenced by `ApiBody` / `ApiResponse`.
These annotations override metadata, add constraints, compose `oneOf`, `anyOf`,
and `allOf` schemas, or force-include unreferenced models:

```dart
@ApiSchema(name: 'User', description: 'A user returned by the API.')
class UserDto {
  @ApiProperty(description: 'Stable user id.', minimum: 1)
  final int id;

  @ApiProperty(
    name: 'fullName',
    required: false,
    minLength: 1,
    maxLength: 80,
    example: 'Ada',
  )
  final String name;

  @ApiProperty(ignore: true)
  final String internalFlag;
}

@ApiSchema(
  oneOf: [CatDto, DogDto],
  discriminator: ApiDiscriminator('kind'),
)
sealed class PetDto {}
```

From 0.3.0, a sealed class becomes a `oneOf` of its subtypes without listing
them, and `@ApiSchema` also accepts `allOf` and `anyOf`. `@ApiProperty(type:)`
states a property's JSON type when a converter changes it.

- `@ApiSchema(ignore: true)` skips auto-inclusion, but referenced classes are
  still generated — the document needs them.
- Property names follow your serialization package. The precedence rules are in
  [Models and serialization](/models/#how-a-property-is-named).
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

### `checkDocumentedRoutes`

Framework-neutral support for a route drift test. It lists the operations of a
generated spec with sample paths (`documentedRoutes`), calls them through a
function you provide, and reports which ones a handler answered:

```dart
final reports = await checkDocumentedRoutes(
  axleOpenApiJson,
  (method, path) async => RouteResponse(await myServer.status(method, path)),
);
```

A route is unrouted when the server answers it exactly as it answers a path
nobody registered, or with `405`. Only `GET`, `HEAD`, and `OPTIONS` are called
by default. See [Keeping paths in sync](/guide/keeping-paths-in-sync).

### Document model and `swaggerUiHtml`

`OpenApiDocument`, `OpenApiInfo`, `OpenApiContact`, `OpenApiLicense`,
`OpenApiServer`, `OpenApiTag`, `OpenApiExternalDocs`, `OpenApiComponents`,
`OpenApiPathItem`, `OpenApiOperation`, `OpenApiParameter`,
`OpenApiRequestBody`, `OpenApiResponse`, `OpenApiHeader`, `OpenApiMediaType`,
`OpenApiExample`,
`OpenApiSecurityScheme`, `OpenApiSecurityRequirement`, and `OpenApiSchema`
(nullable refs, arrays, maps, enums, objects, constraints, and `oneOf`,
`anyOf`, and `allOf` with discriminators) model OpenAPI 3.1 directly.

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
- No auth enforcement, runtime validation, or serialization.
- No runtime route discovery.
