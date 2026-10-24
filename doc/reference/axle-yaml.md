# `axle.yaml` Reference

`axle.yaml` owns global contract identity, deployment metadata, security
schemes, and compiler settings. It is created by `axle init` and is afterwards
the single source of truth — `gen` reads only this file and Dart source, never
`pubspec.yaml`.

## Full example

```yaml
openapi: 3.1.0

info:
  title: Todo API
  version: 0.2.0
  description: A Relic Todo API.
  termsOfService: https://example.com/terms
  contact:
    name: Example
    email: dev@example.com
  license:
    name: MIT

servers:
  - url: https://api.example.com
    description: Production.

tags:
  - name: Todos
    description: Todo operations.
    externalDocs:
      url: https://example.com/todos
      description: Todo guide.

externalDocs:
  url: https://example.com/docs
  description: Full API documentation.

security:
  schemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    apiKey:
      type: apiKey
      in: header
      name: X-API-Key
    oauth:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/authorize
          tokenUrl: https://auth.example.com/token
          scopes:
            read: Read access
  default:
    - bearerAuth

generate:
  scan:
    - lib
  output:
    json: openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

## Fields

| Field | Required | Meaning |
| --- | --- | --- |
| `openapi` | yes | Must be a supported `3.1.x` version |
| `info` | yes | Maps to the OpenAPI Info Object |
| `info.title` | yes | API title; also seeds the Swagger UI title |
| `info.version` | yes | API version |
| `info.description` | no | API description |
| `info.termsOfService` | no | URL to the terms of service |
| `info.contact` | no | `name`, `url`, `email` |
| `info.license` | no | `name`, `identifier`, `url` |
| `servers` | no | Deployment URLs (`url`, optional `description`) |
| `tags` | no | Global tag metadata (`name`, `description`, `externalDocs`) |
| `externalDocs` | no | `url` and optional `description` |
| `security.schemes` | no | Reusable security schemes keyed by name |
| `security.default` | no | Scheme names applied to every operation by default |
| `generate.scan` | yes | One or more directories or files to scan |
| `generate.output.json` | yes | Spec path, relative to the project root (or absolute inside it) |
| `generate.output.ui` | no | Swagger UI asset directory (default: `assets/swagger-ui`) |
| `generate.output.dart` | yes | Dart artifact path for `const String axleOpenApiJson` |

The YAML artifact has **no setting**: `openapi.yaml` is derived by replacing
the JSON extension with `.yaml`, so JSON and YAML can never drift in config.

## Security

Supported scheme types:

| Type | Required fields |
| --- | --- |
| `http` | `scheme` (`basic` or `bearer`); optional `bearerFormat` |
| `apiKey` | `name` and `in` (`header`, `query`, or `cookie`) |
| `oauth2` | At least one flow: `implicit`, `password`, `clientCredentials`, or `authorizationCode` |
| `openIdConnect` | `openIdConnectUrl` |

OAuth2 flows accept `authorizationUrl`, `tokenUrl`, `refreshUrl`, and a `scopes`
map. Required URLs depend on the flow:

- `implicit`: `authorizationUrl`
- `password` / `clientCredentials`: `tokenUrl`
- `authorizationCode`: both

`security.default` is a single requirement over the listed schemes (logical
AND). Use route annotations for alternatives:

```dart
@ApiRoute(
  security: [
    ApiSecurityRequirement(['bearerAuth']),
    ApiSecurityRequirement(['apiKey']),
  ],
)
```

Multiple requirements are alternatives (OR); multiple schemes in one requirement
must all be satisfied (AND). `security: []` makes one operation public. The
generator validates every referenced scheme, but auth enforcement remains in the
application.

## Deliberately absent

| Key | Why |
| --- | --- |
| `docs` | Docs routing and UI title are runtime adapter concerns. |
| `swagger_ui_url` | The default lives in `axle_core` (pinned 5.34.0 + SRI); local assets come from `generate.output.ui`. |

## Rules

- `init` reads `pubspec.yaml` once to seed `info.title` and `info.version`.
- After `init`, `axle.yaml` is authoritative; `gen` never reads `pubspec.yaml`.
- Unknown keys are errors.
- `scan` paths and output paths must stay inside the project root.
- `generate.scan` supports one or more directories or files.
- `info` maps to the OpenAPI Info Object; `openapi` must be supported 3.1.x.
- When `servers` is omitted, Swagger UI uses the current origin.
