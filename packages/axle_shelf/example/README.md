# Shelf Todo API example

A complete Shelf API demonstrating axle_shelf:

- annotated top-level Shelf handlers
- generated `openapi.json`, `openapi.yaml`, and AOT-safe `axleOpenApiJson`
- a Shelf router for application routes
- Swagger UI mounted through `axle_shelf`
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
- <http://localhost:8080/notes>

The port comes from `PORT`, defaulting to `8080`.

## Try the API

```sh
curl http://localhost:8080/notes

curl -X POST http://localhost:8080/notes \
  -H 'content-type: application/json' \
  -d '{"title":"Review the Shelf adapter"}'

curl 'http://localhost:8080/notes?completed=false&limit=10'

curl http://localhost:8080/notes/1

curl -X PATCH http://localhost:8080/notes/1 \
  -H 'content-type: application/json' \
  -d '{"completed":true}'

curl -X DELETE http://localhost:8080/notes/1
```

## Layout

- `lib/src/models/note.dart` — DTOs used to build component schemas.
- `lib/src/repositories/note_repository.dart` — in-memory repository.
- `lib/src/routes/note_routes.dart` — annotated Shelf handlers and router setup.
- `lib/src/generated/openapi.g.dart` — generated AOT-safe spec.
- `openapi.json` / `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/server.dart` — Shelf composition with API, docs, and local assets.

The example serves Swagger UI from generated local assets, so it does not need a
CDN at runtime. If you only need the CDN-backed UI, omit `swaggerUiDirectory`
from `axleDocsHandler`.
