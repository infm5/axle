# Examples

Two complete, runnable Todo APIs ship in the repository. Both demonstrate the
full axle flow: annotated handlers, inferred DTO schemas, generated specs,
generated `openapi.g.dart`, and locally served Swagger UI.

## Relic example

Location: `packages/axle_relic/example/`

```sh
cd packages/axle_relic/example
dart pub get
dart run axle_cli:axle gen
dart run bin/server.dart
```

Then open:

- `http://localhost:8080/docs`
- `http://localhost:8080/openapi.json`
- `http://localhost:8080/health`
- `http://localhost:8080/todos`

Try the API:

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

Layout:

- `lib/src/models/todo.dart` — DTOs inferred into component schemas.
- `lib/src/repositories/todo_repository.dart` — in-memory repository.
- `lib/src/routes/todo_routes.dart` — annotated Relic handlers.
- `lib/src/generated/openapi.g.dart` — generated AOT-safe spec.
- `openapi.json` / `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/server.dart` — Relic app wiring with `mountAxleDocs`.

The port comes from `PORT`, defaulting to `8080`.

## Shelf example

Location: `packages/axle_shelf/example/`

```sh
cd packages/axle_shelf/example
dart pub get
dart run axle_cli:axle gen
dart run bin/server.dart
```

Then open:

- `http://localhost:8080/docs`
- `http://localhost:8080/openapi.json`
- `http://localhost:8080/health`
- `http://localhost:8080/notes`

Try the API:

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

Layout:

- `lib/src/models/note.dart` — DTOs used to build component schemas.
- `lib/src/repositories/note_repository.dart` — in-memory repository.
- `lib/src/routes/note_routes.dart` — annotated Shelf handlers and router setup.
- `lib/src/generated/openapi.g.dart` — generated AOT-safe spec.
- `openapi.json` / `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/server.dart` — Shelf composition with API, docs, and local assets.

The Shelf example serves Swagger UI from generated local assets, so it needs
no CDN at runtime. Omitting `swaggerUiDirectory` from `axleDocsHandler` falls
back to the CDN-backed UI.

## Freshness in CI

Both examples are verified by `gen --check` in the workspace:

```sh
dart run melos run check   # analyze + test + format + spec freshness
```

The examples carry no unit tests by design — `gen --check` is the build-level
verification that the committed specs match the annotated source.
