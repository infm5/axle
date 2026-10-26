# How It Works

## Pipeline

![axle generation pipeline](/architecture.svg)

**Annotate.** Route facts live in `@ApiRoute` on handler functions (and, from
0.3.0, on methods and top-level variables). Type facts live in DTO classes
referenced by `ApiBody` / `ApiResponse`.
`axle.yaml` owns only global contract identity (`openapi`, `info`) and
compiler settings (`generate`).

**Scan.** `axle gen` resolves every `generate.scan` path with
`package:analyzer`, finds `@ApiRoute` annotations, and evaluates their constant
arguments: methods, paths, parameter lists, `Type` literals. It requires
`dart pub get` first, because without resolved dependencies the analyzer cannot
start. If your models use a code generator, run it before `axle gen` so the
generated parts exist.

**Build operations.** Each annotation becomes one OpenAPI operation. The builder
rejects duplicates (route + method, operationId, response status), unused path
parameters, empty paths, wildcard routes, invalid status codes, parameter styles
that do not fit their location, and `example` combined with `examples`. An empty
`responses` list emits `200 OK` with no body.

**Infer schemas.** Each referenced `Type` is resolved through the schema
registry: primitives map to JSON Schema types, collections recurse into
`items` / `additionalProperties`, enums become string enums, and classes become
`$ref` component schemas with their public instance fields as properties. The
registry also applies what your serialization package says about the wire
format: renames, defaults, converters, and freezed or `dart_mappable` models (see
[Models and serialization](/models/)). Generic classes get one schema per
instantiation, and sealed classes become `oneOf`. Unsupported shapes (records,
function types) throw with the offending symbol named. Referenced classes are
always emitted; `@ApiSchema` only force-includes unreferenced models or
overrides metadata.

**Emit.** One deterministic run writes the JSON spec (pretty, trailing
newline), the YAML equivalent, the Swagger UI asset directory, and a
`const String axleOpenApiJson`. Path and schema ordering is deterministic, so
spec diffs reflect API changes only. No file I/O is needed at runtime — the
server imports the constant.

**Serve.** The adapter serves the constant verbatim at `GET {specPath}` and the
Swagger UI shell at `GET {docsPath}`. It binds no application routes. On
Serverpod, these routes live on `pod.webServer`; API-server `Endpoint` methods
are a separate RPC surface.

## Dependency direction

```
axle_core
   ^        ^          ^           ^
   |        |          |           |
axle_cli  axle_relic  axle_shelf  axle_serverpod
              ^          ^           ^
              |          |           |
            apps       apps        apps
```

- `axle_core` has no runtime dependencies and no framework imports.
- Adapters depend on `axle_core` and may re-export it for a one-import app.
- The CLI depends on `axle_core` but never on an adapter.
- No reverse dependencies.

## The shared adapter contract

One `AxleDocs` per mounted docs surface. It owns every behavior adapters would
otherwise duplicate:

```dart
final docs = AxleDocs(
  spec: axleOpenApiJson,
  specPath: '/openapi.json',
  docsPath: '/docs',
  title: null, // explicit title, else info.title, else 'API Docs'
  noCache: true,
);
```

| Member | Behavior |
| --- | --- |
| `specJson` | The exact generated JSON artifact, served verbatim |
| `specPath` / `docsPath` | Trimmed, forced to a leading `/`; empty or identical paths throw `ArgumentError` |
| `title` | Explicit title, else the spec's `info.title` (malformed specs fall back to `API Docs`) |
| `swaggerUiUrl` | Asset base URL; defaults to the pinned CDN with SRI |
| `uiHtml` | Swagger UI shell; title HTML-escaped, spec URL JSON-encoded, SRI applied for the default CDN |
| `headers` | `{'cache-control': 'no-store'}` when `noCache` is true, else empty |

Adapter mapping:

| Route | Body | Content type | Headers |
| --- | --- | --- | --- |
| `GET {specPath}` | `docs.specJson` | `application/json` | `docs.headers` |
| `GET {docsPath}` | `docs.uiHtml` | `text/html; charset=utf-8` | `docs.headers` |

## Failure model

Generator failures are `AxleException`s with a sysexits code, written to
`stderr`. Source errors carry a position and print as
`file:line:column: error: message`. One run reports every source error it finds,
and the first error's code becomes the exit code:

| Code | Meaning | Typical cause |
| --- | --- | --- |
| `0` | Success | — |
| `64` | Usage | Invalid CLI flags |
| `65` | Data | Annotation/schema/route violations in scanned source |
| `70` | Software | Unexpected internal error |
| `78` | Config | Missing/malformed `axle.yaml`, unknown keys, paths outside the project root |

Warnings print as `axle: warning: …` and never change the exit code.

Full catalog: [Troubleshooting](/guide/troubleshooting).

## What stays out

- Binding or generating application routes.
- Runtime request/response validation and serialization.
- Authentication or authorization enforcement. Security metadata is generated,
  but middleware remains application-owned.
- Route discovery from router calls. The generator reads annotations on
  functions, methods, and top-level variables; it does not inspect
  `app.get('/x', ...)` calls.
