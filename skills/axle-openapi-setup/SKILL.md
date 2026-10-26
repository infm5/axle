---
name: axle-openapi-setup
description: >-
  Set up axle to generate and serve high-quality OpenAPI 3.1 documentation for
  Dart HTTP APIs. Use when the user asks to add OpenAPI or Swagger docs to a
  Dart server, document Relic, Shelf, or Serverpod routes, configure
  axle.yaml or axle_cli, annotate handlers with @ApiRoute/@ApiSchema, add
  security schemes, or generate openapi.json/YAML and hosted Swagger UI. Also
  use when generated routes, schemas, docs assets, or validation are missing,
  stale, or failing.
license: MIT
compatibility: Requires a Dart project and Dart SDK; installing pub.dev packages and validating with Redocly need network access.
metadata:
  author: infm5
  version: "0.2.0"
---

# axle OpenAPI Setup

axle is a framework-agnostic OpenAPI 3.1 toolchain for Dart servers:
`axle_core` owns annotations and the document model, `axle_cli` generates the
artifacts, and adapters serve the generated contract.

## Contents

- [1. Inspect the project](#1-inspect-the-project)
- [2. Install the right packages](#2-install-the-right-packages)
- [3. Initialize and shape `axle.yaml`](#3-initialize-and-shape-axleyaml)
- [4. Model DTOs and schemas](#4-model-dtos-and-schemas)
- [5. Annotate routes](#5-annotate-routes)
- [6. Add security metadata](#6-add-security-metadata)
- [7. Generate artifacts](#7-generate-artifacts)
- [8. Mount the docs](#8-mount-the-docs)
- [9. Raise the documentation quality bar](#9-raise-the-documentation-quality-bar)
- [10. Verify before calling it done](#10-verify-before-calling-it-done)
- [References](#references)

## 1. Inspect the project

Before editing, identify:

- The server framework: Relic, Shelf, Serverpod 4 web-server routes, or custom.
- The package name and API version from `pubspec.yaml`.
- Where HTTP handlers live and whether they are top-level functions.
- Where request/response DTOs live and whether they use `json_annotation`.
- Any existing OpenAPI/Swagger setup, generated specs, or docs assets.
- Whether the user wants public docs, internal docs, or both.

For Serverpod, confirm the user means **web-server `Route`s**, not API-server
`Endpoint` RPC methods. axle cannot document Endpoint RPC.

## 2. Install the right packages

Use the adapter package for the framework. It re-exports `axle_core`, so apps
only need the adapter plus the CLI.

| Project | Runtime dependency | Dev dependency |
| --- | --- | --- |
| Relic | `axle_relic` | `axle_cli` |
| Shelf | `axle_shelf` | `axle_cli` |
| Serverpod 4 web routes | `axle_serverpod` | `axle_cli` |
| Custom adapter | `axle_core` | `axle_cli` |

Use `^0.3.0` unless the project pins a later compatible version. Steps below
marked **(0.3.0)** need axle 0.3.0; on `0.2.x`, upgrade first or skip them. Relic currently targets Relic
2.0.0-rc.2. Framework-specific install and mounting snippets are
in [references/frameworks.md](references/frameworks.md).

Run `dart pub get` after editing `pubspec.yaml`.

## 3. Initialize and shape `axle.yaml`

Run:

```sh
dart run axle_cli:axle init
```

`init` reads `pubspec.yaml` once, then `axle.yaml` becomes the source of truth
for API identity, metadata, security, and generator paths. `gen` does not read
`pubspec.yaml`.

A solid starting config:

```yaml
openapi: 3.1.0
info:
  title: Project API
  version: 0.1.0
  description: What this API does and who uses it.
generate:
  scan:
    - lib
  output:
    json: openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

`axle init` defaults `generate.output.json` to `build/openapi.json`. The example
above deliberately puts the spec at the project root for easy serving. Either
keep the init defaults or update the JSON path (and the adapter's spec path)
consistently; do not leave two competing output paths.

Add optional global metadata when it improves the contract:

```yaml
servers:
  - url: https://api.example.com
    description: Production.

tags:
  - name: Users
    description: User lifecycle and profile operations.
    externalDocs:
      url: https://docs.example.com/users

externalDocs:
  url: https://docs.example.com
  description: Full API documentation.

security:
  schemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
  default:
    - bearerAuth
```

Rules that prevent config drift:

- Keep `info.version` as the API's version, not the axle package version.
- Keep `generate.scan` scoped to the directories containing annotated handlers
  and DTOs.
- The YAML artifact is derived from the JSON path; there is no YAML path key.
- Do not add `docs` or `swagger_ui_url`; those are runtime adapter options.
- Add global `security.default` only when every operation should inherit it.
  Use `security: []` on intentionally public operations.

Use `assets/axle.yaml` as a copyable starting point.

## 4. Model DTOs and schemas

Schemas are inferred from classes referenced by request bodies and responses.
Use `@ApiSchema` only to override metadata, force-include a model, or declare
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

  /// When the account was created.
  final DateTime createdAt;

  const UserDto({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
```

Guidance:

- Public instance fields become properties; private/static fields are skipped.
- Non-nullable fields are required unless `required: false` or a default says
  otherwise.
- Put doc comments on fields so the OpenAPI property descriptions are useful.
- Use `@ApiProperty(name: ...)` or `@JsonKey(name: ...)` for wire names.
- `Uint8List`/`ByteData` default to base64-style `string`/`byte`; use
  `@ApiProperty(format: 'binary')` for multipart file parts.
- **(0.3.0)** Sealed classes become `oneOf` of their subtypes automatically; add
  `@ApiSchema(discriminator: ...)` so clients can tell them apart. Use explicit
  `oneOf`, `anyOf`, or `allOf` in `@ApiSchema` for other shapes. With 0.2.0,
  declare `@ApiSchema(oneOf: [...], discriminator: ...)` explicitly.
- **(0.3.0)** If the project uses `json_serializable`, `freezed`, or
  `dart_mappable`, read [references/models.md](references/models.md) first.
  `axle_cli` does not resolve next to freezed 3.x; install it globally instead.
- **(0.3.0)** Declare shared errors once and spread them: `responses:
  [ApiResponse.ok(X), ...protectedErrors]`. Use `ApiResponse.range(4)` and
  `defaultResponse()`.
- **(0.3.0)** Use `style:`/`explode:` on array query parameters and `examples:`
  for named examples.
- **(0.3.0)** Add a test that every documented path is served:
  `checkShelfRoutes(router.call, spec: axleOpenApiJson)` for Shelf, or
  `checkDocumentedRoutes` for any framework. Share each path in one constant too.
- **(0.3.0)** When one status returns different formats with different schemas
  (JSON and CSV), declare the status once per media type and axle merges them.
  Use `ApiRoute(bodies: [...])` for request bodies the same way. Raw bytes
  (`Uint8List`) under a non-JSON media type are `format: binary`.
- Avoid exposing internal fields; mark them `@ApiProperty(ignore: true)`.

## 5. Annotate routes

Annotations go on top-level functions. **(0.3.0)** They can also go on methods
of classes and mixins, and on top-level variables that hold a closure. Closures
passed inline to a router are never discovered. For Serverpod with 0.2.0,
annotate a top-level delegate and call it from `Route.handleCall`; with 0.3.0 you
can annotate `handleCall` itself.

```dart
@ApiRoute(
  method: ApiMethod.get,
  path: '/users/:id',
  summary: 'Get a user',
  description: 'Returns one active user by id.',
  tags: ['Users'],
  pathParams: [
    ApiPathParam('id', type: int, minimum: 1, description: 'User id.'),
  ],
  security: [ApiSecurityRequirement(['bearerAuth'])],
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse.badRequest(ApiError),
    ApiResponse(
      status: 401,
      type: ApiError,
      description: 'Missing or invalid access token.',
    ),
    ApiResponse.notFound(ApiError),
  ],
)
Future<Result> getUser(Request request) async { ... }
```

Keep the annotation path and the framework route path derived from the same
constant so they cannot drift:

```dart
const userPath = '/users/:id';
```

Shelf's router uses `<id>` for path parameters while the generic annotation
syntax uses `:id`; axle accepts either and normalizes Shelf paths. For a Shelf
app, prefer `<id>` in the shared constant so the same value works for both the
annotation and `shelf_router`:

```dart
const userPath = '/users/<id>';
```

Common additions:

- Body: `body: ApiBody(CreateUser)`; use `contentTypes` for multiple media types.
- Response headers: use the main `ApiResponse` constructor with
  `headers: [ApiResponseHeader('Location', type: String)]`.
- Cookies: `ApiCookieParam('session', type: String)`.
- Constraints: `format`, `enumValues`, `minimum`, `maximum`, `minLength`,
  `maxLength`, and `pattern`.
- Multiple response media types: main `ApiResponse` with `contentTypes`.
- Multipart: `ApiBody(UploadDto, contentTypes: ['multipart/form-data'])`.
- Wildcard routes: mark `ignore: true` when OpenAPI cannot represent them.

Detailed recipes are in [references/annotations-recipes.md](references/annotations-recipes.md).

## 6. Add security metadata

Define schemes once in `axle.yaml`; reference them from routes. Supported types
are `http`, `apiKey`, `oauth2`, and `openIdConnect`. Scheme references are
validated during generation.

```dart
@ApiRoute(
  method: ApiMethod.get,
  path: '/me',
  security: [ApiSecurityRequirement(['bearerAuth'])],
  responses: [
    ApiResponse.ok(UserDto),
    ApiResponse(
      status: 401,
      type: ApiError,
      description: 'Missing or invalid access token.',
    ),
  ],
)
```

Semantics:

- `security` omitted/`null`: inherit document default.
- `security: []`: public operation.
- Multiple requirements: OR alternatives.
- Multiple schemes in one requirement: AND.
- OAuth2 scopes: `ApiSecurityRequirement(['oauth'], scopes: {'oauth': ['read']})`.

Security metadata does **not** enforce auth. Keep token validation and
authorization in middleware or framework auth. Only document auth that the
service actually enforces; otherwise the contract is misleading.

## 7. Generate artifacts

```sh
dart run axle_cli:axle gen
```

One run writes:

| Artifact | Default | Purpose |
| --- | --- | --- |
| `openapi.json` | `generate.output.json` | Tooling, client generation, diffs |
| `openapi.yaml` | JSON path with `.yaml` | YAML consumers |
| `assets/swagger-ui/` | `generate.output.ui` | Self-hosted Swagger UI |
| `openapi.g.dart` | `generate.output.dart` | AOT-safe `const String` spec |

Never hand-edit generated artifacts. Edit annotations/config and regenerate.

For CI, use:

```sh
dart run axle_cli:axle gen --check
```

`--check` fails when JSON, YAML, UI assets, or the Dart const are stale.

## 8. Mount the docs

Use the framework adapter. Keep the generated spec and local assets together.

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

Omit `swaggerUiDirectory` only when the pinned CDN UI is acceptable. For
offline or production docs, keep local assets. Custom paths must keep
`swaggerUiPath` distinct from `/`, the spec path, and the docs path.

For a custom server, use `AxleDocs(spec: axleOpenApiJson)` and serve
`specJson`, `specPath`, `docsPath`, `uiHtml`, and `headers` yourself. See
[references/frameworks.md](references/frameworks.md) and the adapter authoring
guide linked there.

## 9. Raise the documentation quality bar

Great generated docs are more than a list of routes. Check each operation:

- Has a concise `summary` and a useful `description` for non-obvious behavior.
- Has stable, unique `operationId`s (the function name is the default).
- Has tags that match the global tag metadata.
- Documents realistic success responses and likely `400`, `401`, `403`, `404`,
  or `409` failures.
- Documents security on protected operations and `security: []` on public ones.
- Uses constraints that match runtime validation.
- Includes examples for important request/response fields and error shapes.
- Uses `deprecated: true` instead of silently leaving obsolete routes in place.
- Exposes no secrets, internal ids, or fields that should remain private.
- Uses `externalDocs`/`termsOfService` when the API has a real docs home.

Use the quality checklist in
[references/quality-checklist.md](references/quality-checklist.md).

## 10. Verify before calling it done

Run, in order:

```sh
dart pub get
dart run axle_cli:axle gen
dart analyze
dart run axle_cli:axle gen --check
dart run bin/server.dart   # or the project's normal server command
```

Generate before `dart analyze` on a fresh setup: server code may import the
generated `openapi.g.dart`, so analyzing first can fail with a missing generated
file error.

Then verify:

- `/openapi.json` returns the generated document.
- `/docs` renders Swagger UI and models expand without errors.
- Authorize works when security schemes are present.
- `/docs-assets/*` assets load when self-hosting.
- Protected routes return the documented `401` without credentials.
- The generated spec validates with the project's chosen OpenAPI linter.

If generation or serving fails, use
[references/troubleshooting.md](references/troubleshooting.md). Do not work
around errors by hand-editing the generated spec.

## References

- [Framework install and mounting recipes](references/frameworks.md)
- [Annotation and DTO recipes](references/annotations-recipes.md)
- [Models and serialization packages](references/models.md)
- [Documentation quality checklist](references/quality-checklist.md)
- [Troubleshooting and validation](references/troubleshooting.md)
- [Copyable axle.yaml template](assets/axle.yaml)
- [adapter authoring guide](https://github.com/infm5/axle/blob/master/docs/adapter-authoring.md)
