# axle showcase

One Shelf server that uses nearly every corner of axle, with a real handler
behind every route. It has **44 paths and 50 operations**, speaks **20 media
types**, documents **37 headers** and **30 status keys**, and uses **all four
security scheme types** (seven schemes, with API keys in a header, a query
parameter, and a cookie). Open it in Swagger UI and try any of it.

```sh
dart pub get
dart run axle_cli:axle gen
dart run bin/server.dart          # http://localhost:8080/docs
```

## It is tested against its own spec

`test/conformance_test.dart` starts the server, calls every route, and checks the
response against the generated `openapi.json`:

1. the status code is declared (exactly, as a range such as `4XX`, or as `default`);
2. the response's media type is declared for that status;
3. a JSON body validates against the declared schema (NDJSON, line by line);
4. every header the spec marks `required` is present.

```sh
dart test      # 66 checks
```

`test/routes_test.dart` adds the other half: it calls every documented path on the
router and fails if a path in the spec is no longer served, so renaming a route in
one place but not the other is caught. It also proves that by renaming a route and
expecting the report.

The first run of this test found three places where an annotation did not match
its handler. That is the point of it: a spec you cannot trust is worse than none.

## What is in it

| Area | What it shows | Routes |
| --- | --- | --- |
| **Media types** | JSON, XML, YAML, plain text, HTML, Markdown, CSV, TSV, NDJSON, server-sent events, PNG, SVG, PDF, raw bytes, `multipart/form-data`, form-urlencoded, `merge-patch+json`, `json-patch+json`, a vendor type, `problem+json` | `/media/*` |
| **Content negotiation** | One status, a different schema per media type, chosen by `Accept` with q-values | `/media/greeting`, `/media/report`, `/media/logo` |
| **Binary** | Raw bytes are `format: binary`; bytes inside JSON stay base64. Ranges (`206`, `416`) | `/media/blob`, `/media/document.pdf` |
| **Uploads** | Fields, one cover, many attachments (`format: binary` on each file), raw `PUT` | `/media/upload`, `/media/blob` |
| **Several bodies** | One `PATCH` accepting two patch formats with different schemas | `/media/documents/{id}` |
| **Headers** | `ETag`, `Last-Modified`, `If-None-Match`, `If-Match`, `Idempotency-Key`, `X-RateLimit-*`, `Retry-After`, `Link`, `Accept-Language`, `Deprecation`, `Sunset`, `Content-Range`, `Content-Disposition`, and more | `/headers/*` |
| **Status codes** | `200`…`503`, redirects, `202` jobs, `204`, `304`, `412`, `428`, plus `2XX`, `3XX`, `4XX`, `5XX`, and `default` | `/responses/*` |
| **Parameters** | Arrays and objects in every style: `form`, `pipeDelimited`, `spaceDelimited`, `deepObject`, path `simple`, `label`, `matrix`; cookies; formats; patterns; bounds | `/parameters/*` |
| **Security** | API key (header, query, cookie), Basic, Bearer, OAuth2 with scopes, OpenID Connect, AND, OR, and public routes | `/security/*` |
| **Schemas** | Generics, a sealed `oneOf` with a discriminator, `anyOf`, three-level `allOf`, a union as a request body, recursion, maps, sets, nullable, and a model with a field of every type | `/schemas/*` |
| **Methods** | `GET`, `HEAD`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` | everywhere |
| **Document** | Description, terms, contact, license, two servers, six tagged groups with external docs | `axle.yaml` |

## Try it

Demo credentials: API key `demo-key`, bearer token `demo-token`, Basic
`demo` / `demo`, OAuth2 and OpenID token `demo-oauth`.

```sh
# The same greeting in six formats.
curl -H 'Accept: text/markdown' 'localhost:8080/media/greeting?name=Ada'
curl -H 'Accept: application/xml' localhost:8080/media/greeting
curl -H 'Accept: text/html;q=0.9, application/json;q=0.5' localhost:8080/media/greeting

# A report you can download.
curl -H 'Accept: text/csv' localhost:8080/media/report

# Streams.
curl 'localhost:8080/media/stream/ndjson?count=3'
curl 'localhost:8080/media/stream/events?count=3'

# Binary: an image, a PDF, and a byte range.
curl -H 'Accept: image/png' localhost:8080/media/logo -o logo.png
curl localhost:8080/media/document.pdf -o showcase.pdf
curl -H 'Range: bytes=0-9' localhost:8080/media/blob | xxd

# A multipart upload with several files.
curl -F title=Trip -F tags=a -F tags=b -F cover=@logo.png \
     -F attachments=@showcase.pdf -F attachments=@logo.png \
     localhost:8080/media/upload

# Sign in with a form, then use the token.
curl -d 'username=demo&password=demo' localhost:8080/media/login
curl -H 'Authorization: Bearer demo-token' localhost:8080/security/bearer

# Conditional requests.
curl -i localhost:8080/headers/cache/1
curl -i -H 'If-None-Match: "1-1"' localhost:8080/headers/cache/1
curl -i -X PUT localhost:8080/headers/cache/1 -d '{"name":"x","price":1}'   # 428

# Arrays and objects in a query string.
curl -g 'localhost:8080/parameters/search?tags=a&tags=b&ids=1,2,3&sort=name|-price&filter[color]=red'

# Any status code, and the rate limit.
curl -i localhost:8080/responses/status/418
for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{http_code} ' localhost:8080/headers/rate-limited; done
```

## How it is organized

```text
axle.yaml                    identity, servers, tags, and all seven security schemes
lib/src/models/              plain Dart classes; axle reads their fields
lib/src/routes/
  shared.dart                const lists spread into every operation (errors, auth)
  media_routes.dart          content types in and out
  header_routes.dart         request and response headers
  parameter_routes.dart      parameters of every style
  security_routes.dart       one route per scheme
  schema_routes.dart         unions, composition, generics, recursion
  response_routes.dart       status codes and async jobs
test/conformance_test.dart   the server against its own spec
```

Annotation constants are reused instead of repeated. `shared.dart` defines the
`problem+json` errors once, and each route spreads them in:

```dart
responses: [
  ApiResponse(status: 200, type: Item),
  badRequest,
  ...authErrors,        // 401 and 403
  ...catchAllErrors,    // 4XX, 5XX, and default
],
```

## Where axle stops

Things this API cannot express yet, so you do not look for them:

- `info.summary`, and server variables.
- `uniqueItems` for a `Set`. A set becomes a plain array.
- Constraints or formats on a response header. Headers carry a type and an example.
- Webhooks, callbacks, links, and `x-` extensions.
- Routes registered only through inline closures. Annotate a function or method.

`Accept`, `Content-Type`, and `Authorization` are not declared as header
parameters on purpose: OpenAPI ignores them there. The media types of the
request and response carry that information, and the security schemes carry the
credentials.
