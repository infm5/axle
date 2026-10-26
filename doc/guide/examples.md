# Examples

Six runnable examples ship in the repository, and the **showcase** is the best place to start. They demonstrate the full axle
flow: annotated handlers, inferred DTO schemas, generated specs, generated
`openapi.g.dart`, and locally served Swagger UI.

- The **showcase** is one server that uses nearly every corner of axle, and is
  tested against its own spec. See [below](#showcase).
- The **Relic**, **Shelf**, and **Serverpod** examples show each framework. The
  Relic and Shelf examples also exercise security requirements, response headers,
  cookie parameters, content negotiation, constraints, `oneOf` discriminators,
  and multipart uploads against real handlers.
- The **dart_mappable** and **freezed** examples show model packages, and the
  Shelf example uses `json_serializable`. They use 0.3.0 features, so they run
  against the local packages in the repository, not the published `0.2.0`.

Both Todo examples use the demo API key `demo-key` in the `X-API-Key` header for
their protected statistics and import routes. That key is example data only;
real applications should keep enforcement in middleware and secrets outside the
source tree.

## Showcase

Location: `examples/showcase/`

A Shelf server with a real handler behind every route: 44 paths, 50 operations,
20 media types, 37 headers, 30 status keys, all four security scheme types
(seven schemes), and seven HTTP methods. Use it to see what axle can document and
to copy a pattern.

```sh
cd examples/showcase
dart pub get
dart run axle_cli:axle gen
dart run bin/server.dart       # http://localhost:8080/docs
dart test                      # 66 checks against the generated spec
```

| Area | What it shows |
| --- | --- |
| Media types | JSON, XML, YAML, text, HTML, Markdown, CSV, TSV, NDJSON, server-sent events, PNG, SVG, PDF, raw bytes, multipart, form-urlencoded, merge-patch, JSON Patch, a vendor type, `problem+json` |
| Headers | `ETag`, `If-Match`, `Idempotency-Key`, `X-RateLimit-*`, `Retry-After`, `Link`, `Accept-Language`, `Deprecation`, `Sunset`, `Content-Range`, and more |
| Parameters | Arrays and objects in every style, path styles, cookies, formats |
| Security | API keys in a header, query, and cookie; Basic; Bearer; OAuth2 scopes; OpenID Connect; AND, OR, public |
| Schemas | Generics, sealed `oneOf`, `anyOf`, `allOf`, recursion, a model with every type |
| Responses | Exact codes, `2XX` to `5XX`, `default`, redirects, async jobs |

`test/conformance_test.dart` is what makes it more than a demo. It calls every
route and checks the status, the media type, the JSON body, and the required
headers against `openapi.json`. `test/routes_test.dart` checks that every path in
the spec is still served by the router. See the
[README](https://github.com/infm5/axle/tree/master/examples/showcase) for the
full tour and the curl cookbook.

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

# Security: 401 without the key, 200 with it.
curl -i http://localhost:8080/todos/stats
curl -i -H 'X-API-Key: demo-key' \
  -H 'Cookie: session=demo-session' \
  -H 'Accept: application/vnd.axle+json' \
  'http://localhost:8080/todos/stats?window=active'

# oneOf/discriminator response.
curl http://localhost:8080/todos/activity

# Multipart upload.
curl -i -X POST http://localhost:8080/todos/import \
  -H 'X-API-Key: demo-key' \
  -F 'file=@README.md'
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

# Security: 401 without the key, 200 with it.
curl -i http://localhost:8080/notes/stats
curl -i -H 'X-API-Key: demo-key' \
  -H 'Cookie: session=demo-session' \
  -H 'Accept: application/vnd.axle+json' \
  'http://localhost:8080/notes/stats?window=active'

# oneOf/discriminator response.
curl http://localhost:8080/notes/activity

# Multipart upload.
curl -i -X POST http://localhost:8080/notes/import \
  -H 'X-API-Key: demo-key' \
  -F 'file=@README.md'
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

## Serialization package examples

Three examples show real model packages. Each one checks that the spec matches
the JSON the server sends. See [Models and serialization](/models/).

| Example | Package | Run |
| --- | --- | --- |
| `packages/axle_shelf/example` | `json_serializable` | `dart run build_runner build` then `dart run axle_cli:axle gen` |
| `examples/dart_mappable` | `dart_mappable` | `dart run build_runner build` then `dart run axle_cli:axle gen` |
| `examples/freezed_unions` | `freezed` (data classes and a union) | `dart run build_runner build` then `axle gen` with the globally activated CLI |

## Freshness in CI

Every example is verified by `gen --check`:

```sh
dart run melos run check   # analyze + test + format + spec freshness
```

The Serverpod, dart_mappable, freezed, and showcase examples are standalone
packages, so each has its own script:

```sh
dart run melos run check-serverpod-example
dart run melos run check-dart-mappable-example
dart run melos run check-freezed-example
dart run melos run check-showcase-example
```

The examples carry no unit tests by design — `gen --check` is the build-level
verification that the committed specs match the annotated source.
