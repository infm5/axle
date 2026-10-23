# Relic Todo API example

A proper Relic Todo API demonstrating axle's full flow:

- DTO inference from Dart classes
- annotated top-level Relic handlers
- generated `openapi.json` and `openapi.yaml`
- generated AOT-safe `axleOpenApiJson`
- Swagger UI mounted through `axle_relic`
- local Swagger UI assets generated into `assets/swagger-ui` by `axle gen`

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
```

## Layout

- `lib/src/models/todo.dart` — DTOs inferred into component schemas.
- `lib/src/repositories/todo_repository.dart` — in-memory repository.
- `lib/src/routes/todo_routes.dart` — annotated Relic handlers.
- `lib/src/generated/openapi.g.dart` — generated AOT-safe spec.
- `openapi.json` and `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/server.dart` — Relic app wiring.

`axle.yaml` contains only global API identity and generator paths. Route metadata
stays in the annotations next to the handlers. The example does not configure a
server URL or auth; Relic owns the runtime address, and auth is intentionally out
of scope for axle v0.1.
