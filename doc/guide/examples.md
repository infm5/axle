# Examples

Three complete, runnable examples ship in the repository. They demonstrate the
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

## Serverpod example

Location: `packages/axle_serverpod/example/`

This is a Docker-free Serverpod mini app. It mounts axle docs on the Serverpod
web server and documents a REST `/greeting` route backed by the generated
`GreetingEndpoint` and `Greeting` protocol model.

```sh
cd packages/axle_serverpod/example
dart pub get

cd axle_serverpod_example_server
dart run axle_cli:axle gen
dart run bin/main.dart
```

Then open:

- `http://localhost:8082/greeting?name=Axle`
- `http://localhost:8082/swagger`
- `http://localhost:8082/openapi.json`
- `http://localhost:8082/docs-assets/swagger-ui.css`

Try the API:

```sh
curl 'http://localhost:8082/greeting?name=Axle'
```

Layout:

- `lib/server.dart` — registers the REST route and `pod.webServer.mountAxleDocs`.
- `lib/src/api/greeting_api.dart` — annotated top-level handler and `Route`.
- `lib/src/axle/openapi.g.dart` — generated AOT-safe spec.
- `lib/src/greetings/` — generated Serverpod endpoint and greeting model.
- `openapi.json` / `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/main.dart` — Serverpod entrypoint.

The Serverpod **web server** runs on `8082`; the API server is on `8090` and
Insights on `8091`. `/greeting` and the docs are web-server routes, so
`serverpod start` does not list them in its Endpoint explorer.

## Freshness in CI

All three examples are verified by `gen --check`:

```sh
dart run melos run check   # analyze + test + format + spec freshness
```

The Serverpod example is a self-contained nested workspace, so the outer
workspace uses a dedicated check:

```sh
dart run melos run check-serverpod-example
```

The examples carry no unit tests by design — `gen --check` is the build-level
verification that the committed specs match the annotated source.
