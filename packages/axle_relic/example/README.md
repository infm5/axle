# Relic Todo API example

A proper Relic Todo API demonstrating axle's full flow:

- DTO inference from Dart classes
- annotated top-level Relic handlers
- generated `openapi.json` and `openapi.yaml`
- generated AOT-safe `axleOpenApiJson`
- Swagger UI mounted through `axle_relic`
- local Swagger UI assets generated into `assets/swagger-ui` by `axle gen`
- API key security metadata and real `X-API-Key` checks
- response headers, cookie parameters, and content negotiation
- parameter/property constraints and a `oneOf` activity schema
- a multipart import body with a binary file property

## Run

```sh
dart pub get
dart run axle_cli:axle gen
dart run bin/server.dart
```

Then open:

- <http://localhost:8080/docs>
- <http://localhost:8080/openapi.json>
- <http://localhost:8080/health>
- <http://localhost:8080/todos>

The port comes from `PORT`, defaulting to `8080`.

## Try the API

```sh
curl http://localhost:8080/todos

curl -X POST http://localhost:8080/todos \
  -H 'content-type: application/json' \
  -d '{"title":"Review the axle spec","description":"Check schemas and responses."}'

curl http://localhost:8080/todos/1

curl -X PATCH http://localhost:8080/todos/1 \
  -H 'content-type: application/json' \
  -d '{"completed":true}'

curl -X DELETE http://localhost:8080/todos/1

# Protected endpoint: 401 without the demo key.
curl -i http://localhost:8080/todos/stats

# Protected + cookie + content negotiation + response headers.
curl -i \
  -H 'X-API-Key: demo-key' \
  -H 'Cookie: session=demo-session' \
  -H 'Accept: application/vnd.axle+json' \
  'http://localhost:8080/todos/stats?window=active'

# oneOf/discriminator response.
curl http://localhost:8080/todos/activity

# Multipart upload (the example reports the received byte count).
curl -i -X POST http://localhost:8080/todos/import \
  -H 'X-API-Key: demo-key' \
  -F 'file=@README.md'
```

The example API key is `demo-key`. It is intentionally public demo data; use
real middleware and secrets in a real application.

## Layout

- `lib/src/models/todo.dart` — DTOs, constraints, activity `oneOf`, and upload models.
- `lib/src/repositories/todo_repository.dart` — in-memory repository.
- `lib/src/routes/todo_routes.dart` — annotated Relic handlers, API key checks, and content negotiation.
- `lib/src/generated/openapi.g.dart` — generated AOT-safe spec.
- `openapi.json` and `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/server.dart` — Relic app wiring.

`axle.yaml` holds global API identity, tags, external docs, the `apiKey` security
scheme, and generator paths. Route metadata stays in the annotations next to the
handlers. The adapter serves the generated security metadata; the example handler
enforces the demo key. Relic still owns the runtime address.
