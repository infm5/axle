# axle-openapi-setup

The `axle-openapi-setup` skill walks an agent from installation to verified,
high-quality OpenAPI 3.1 docs for a Dart HTTP API.

Source: [`skills/axle-openapi-setup`](https://github.com/infm5/axle/tree/master/skills/axle-openapi-setup)
in the axle repo. Install it with:

```sh
npx skills add infm5/axle --skill axle-openapi-setup
```

## What the skill covers

- Installing `axle_core`, `axle_cli`, and the right adapter.
- Initializing and shaping `axle.yaml`.
- Modeling DTOs and schemas.
- Annotating routes, parameters, bodies, responses, headers, cookies, security,
  media types, multipart uploads, and `oneOf`.
- Generating JSON/YAML/Dart artifacts and local Swagger UI assets.
- Mounting docs in Relic, Shelf, Serverpod 4 web routes, or a custom adapter.
- Verifying generated specs and improving documentation quality.

## 1. Inspect the project

Before editing, identify:

- The server framework: Relic, Shelf, Serverpod 4 web-server routes, or custom.
- The package name and API version from `pubspec.yaml`.
- Where HTTP handlers live and whether they are top-level functions.
- Where request/response DTOs live and whether they use `json_annotation`.
- Any existing OpenAPI/Swagger setup, generated specs, or docs assets.
- Whether the user wants public docs, internal docs, or both.

For Serverpod, confirm the target is **web-server `Route`s**, not API-server
`Endpoint` RPC methods. axle cannot document Endpoint RPC. See
[axle_serverpod](/packages/serverpod).

## 2. Install the right packages

Use the adapter package for the framework. It re-exports `axle_core`, so apps
only need the adapter plus the CLI.

| Project | Runtime dependency | Dev dependency |
| --- | --- | --- |
| Relic | `axle_relic` | `axle_cli` |
| Shelf | `axle_shelf` | `axle_cli` |
| Serverpod 4 web routes | `axle_serverpod` | `axle_cli` |
| Custom adapter | `axle_core` | `axle_cli` |

Use `^0.2.0` unless the project pins a later compatible version. Then run
`dart pub get`. Full install snippets are in
[Getting Started](/guide/getting-started).

## 3. Initialize and shape `axle.yaml`

```sh
dart run axle_cli:axle init
```

`init` reads `pubspec.yaml` once, then `axle.yaml` becomes the source of truth
for API identity, metadata, security, and generator paths. `gen` does not read
`pubspec.yaml`.

Add optional global metadata when it improves the contract: `servers`, `tags`,
`externalDocs`, and `security`. Keep route tags on `@ApiRoute` and declare
security schemes once under `security.schemes`. The YAML artifact is derived
from the JSON path. Details: [axle.yaml reference](/reference/axle-yaml).

A copyable starting config ships with the skill at
[`skills/axle-openapi-setup/assets/axle.yaml`](https://github.com/infm5/axle/blob/master/skills/axle-openapi-setup/assets/axle.yaml).

## 4. Model DTOs and schemas

Schemas are inferred from classes referenced by request bodies and responses.
Use `@ApiSchema` to override metadata, force-include a model, or declare
explicit `oneOf` composition.

```dart
@ApiSchema(description: 'A user returned by the API.')
class UserDto {
  /// Stable user id.
  @ApiProperty(example: 42, minimum: 1)
  final int id;

  /// Display name.
  @ApiProperty(minLength: 1, maxLength: 80, example: 'Ada Lovelace')
  final String name;

  const UserDto({required this.id, required this.name});
}
```

Guidance:

- Public instance fields become properties; private/static fields are skipped.
- Non-nullable fields are required unless `required: false` or a default says
  otherwise.
- Put doc comments on fields so property descriptions are useful.
- Use `@ApiProperty(name: ...)` or `@JsonKey(name: ...)` for wire names.
- `Uint8List`/`ByteData` default to `string`/`byte`; use
  `@ApiProperty(format: 'binary')` for multipart file parts.
- Declare polymorphic responses explicitly with
  `@ApiSchema(oneOf: [...], discriminator: ...)`.

Full rules: [Annotations & DTO Mapping](/reference/annotations).

## 5. Annotate routes

Annotations must be on top-level functions. For Serverpod, annotate a
top-level delegate and call it from `Route.handleCall`.

```dart
@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  summary: 'Get a user',
  tags: ['Users'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'User id.'),
  ],
  security: [ApiSecurityRequirement(['bearerAuth'])],
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Result> getUser(Request request) async { ... }
```

Keep the annotation path and the framework route path derived from the same
constant. For Shelf, use the router's `<id>` syntax in that constant; axle
normalizes it to `{id}`.

Route features:

- Bodies: `body: ApiBody(CreateUser)`; set `contentTypes` for multiple media
  types.
- Response headers: use the main `ApiResponse` constructor with `headers`.
- Cookies: `ApiCookieParam('session', type: String)`.
- Constraints: `format`, `enumValues`, `minimum`, `maximum`, `minLength`,
  `maxLength`, `pattern`.
- Multipart: `ApiBody(UploadDto, contentTypes: ['multipart/form-data'])`.
- Wildcards: `ignore: true` when OpenAPI cannot represent the route.

## 6. Add security metadata

Define schemes once in `axle.yaml`; reference them from routes. Supported
types are `http`, `apiKey`, `oauth2`, and `openIdConnect`.

```dart
security: [ApiSecurityRequirement(['bearerAuth'])]
```

- Omitted/`null` inherits the document default.
- `security: []` marks a public operation.
- Multiple requirements are OR; schemes in one requirement are AND.
- OAuth2 scopes: `ApiSecurityRequirement(['oauth'], scopes: {'oauth': ['read']})`.

Security metadata does **not** enforce auth. Enforce it in middleware or
framework auth. See [Getting Started](/guide/getting-started#_7-secure-endpoints).

## 7. Generate artifacts

```sh
dart run axle_cli:axle gen
```

One run writes `openapi.json`, `openapi.yaml`, `assets/swagger-ui/`, and
`openapi.g.dart`. Never hand-edit generated artifacts. In CI, use
`dart run axle_cli:axle gen --check`. See
[Getting Started](/guide/getting-started#_4-generate-the-artifacts).

## 8. Mount the docs

Relic:

```dart
app.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

Shelf:

```dart
final docs = axleDocsHandler(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

Serverpod:

```dart
pod.webServer.mountAxleDocs(
  spec: axleOpenApiJson,
  swaggerUiDirectory: 'assets/swagger-ui',
);
```

For a custom server, serve `AxleDocs(spec: axleOpenApiJson)` values
(`specJson`, `specPath`, `docsPath`, `uiHtml`, `headers`) yourself. See
[Building an Adapter](/adapters/building-an-adapter).

## 9. Verify before calling it done

```sh
dart pub get
dart run axle_cli:axle gen
dart analyze
dart run axle_cli:axle gen --check
```

Then verify `/openapi.json` returns the document, `/docs` renders Swagger UI,
Authorize works when security is present, local assets load when self-hosting,
protected routes return the documented `401`, and the spec passes an OpenAPI
linter. See [Troubleshooting](/guide/troubleshooting).

## References in the skill repo

- `references/frameworks.md` — framework install and mounting recipes.
- `references/annotations-recipes.md` — DTO and security patterns.
- `references/quality-checklist.md` — contract, security, and freshness checks.
- `references/troubleshooting.md` — common errors and validation.
- `assets/axle.yaml` — copyable starting config.

Install the skill to get all of these loaded automatically:

```sh
npx skills add infm5/axle --skill axle-openapi-setup
```
