# Shelf Todo API example

A complete Shelf API demonstrating axle_shelf:

- annotated top-level Shelf handlers
- generated `openapi.json`, `openapi.yaml`, and AOT-safe `axleOpenApiJson`
- a Shelf router for application routes
- Swagger UI mounted through `axle_shelf`
- local Swagger UI assets generated into `assets/swagger-ui` by `axle gen`
- API key security metadata and real `X-API-Key` checks
- response headers, cookie parameters, and content negotiation
- parameter/property constraints and a `oneOf` activity schema
- a multipart import body with a binary file property
- `json_serializable` response models: `toJson` is generated, and the spec is
  unchanged from the hand-written version (see `lib/src/models/note.dart`)

## Run

```sh
dart pub get
dart run build_runner build   # only after changing lib/src/models/note.dart
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

# Protected endpoint: 401 without the demo key.
curl -i http://localhost:8080/notes/stats

# Protected + cookie + content negotiation + response headers.
curl -i \
  -H 'X-API-Key: demo-key' \
  -H 'Cookie: session=demo-session' \
  -H 'Accept: application/vnd.axle+json' \
  'http://localhost:8080/notes/stats?window=active'

# oneOf/discriminator response.
curl http://localhost:8080/notes/activity

# Multipart upload (the example reports the received byte count).
curl -i -X POST http://localhost:8080/notes/import \
  -H 'X-API-Key: demo-key' \
  -F 'file=@README.md'
```

The example API key is `demo-key`. It is intentionally public demo data; use
real middleware and secrets in a real application.

## Layout

- `lib/src/models/note.dart` — DTOs, constraints, activity `oneOf`, and upload models.
- `lib/src/repositories/note_repository.dart` — in-memory repository.
- `lib/src/routes/note_routes.dart` — annotated Shelf handlers, API key checks, and content negotiation.
- `lib/src/generated/openapi.g.dart` — generated AOT-safe spec.
- `openapi.json` / `openapi.yaml` — generated specs for tooling.
- `assets/swagger-ui/` — generated Swagger UI assets served locally.
- `bin/server.dart` — Shelf composition with API, docs, and local assets.

`axle.yaml` holds global API identity, tags, external docs, the `apiKey` security
scheme, and generator paths. The adapter serves the generated security metadata;
the example handlers enforce the demo key.

The example serves Swagger UI from generated local assets, so it does not need a
CDN at runtime. If you only need the CDN-backed UI, omit `swaggerUiDirectory`
from `axleDocsHandler`.
