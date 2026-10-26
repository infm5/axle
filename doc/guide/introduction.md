# Introduction

axle generates and serves **OpenAPI 3.1** contracts for Dart HTTP servers.

Two halves, split the way Swaggo splits `swag` from its framework packages:

1. **Generate** — the `axle` CLI statically analyzes annotated handlers and DTO
   classes, then writes spec artifacts.
2. **Serve** — a thin adapter (`axle_relic`, `axle_shelf`, `axle_serverpod`)
   mounts the generated spec and Swagger UI on a running server. Serverpod docs
   are served from the web server, not the API/RPC server.

## What OpenAPI is for

An OpenAPI document is a contract description, not an implementation:

1. Human documentation via Swagger UI or ReDoc.
2. Typed client/SDK generation.
3. Contract linting and review.
4. Mock servers generated from examples and schemas.
5. API catalogs, gateways, developer portals.
6. Diffing the generated spec to catch accidental API changes.

## What axle is not

- An auth system. It can describe security schemes and requirements, but the
  application still enforces auth.
- A router, runtime registry, or route-discovery mechanism.
- A request validator or serializer.
- A substitute for framework middleware.

Annotations describe the API. They do not bind requests, validate input, or
serialize responses — the server framework owns all runtime behavior.

## The packages

| Package | Purpose |
| --- | --- |
| `axle_core` | Annotations, OpenAPI 3.1 document model, `AxleDocs`, Swagger UI HTML. Zero framework dependencies. |
| `axle_cli` | `axle init` / `axle gen`. Analyzer-based scanning; emits JSON, YAML, Dart const, UI assets. |
| `axle_relic` | Relic adapter. `mountAxleDocs(...)` plus standalone handlers. Re-exports core. |
| `axle_shelf` | Shelf adapter. Composable `axleDocsHandler` plus standalone handlers. Re-exports core. |
| `axle_serverpod` | Serverpod adapter. `pod.webServer.mountAxleDocs(...)` for web-server routes. Re-exports core. |

Detail: [Packages](/packages/). Architecture: [How It Works](/guide/how-it-works).
Rationale: [Design Decisions](/guide/design-decisions).

## Scope

- Server-side Dart only. Relic, Shelf, and Serverpod adapters share a
  framework-agnostic core. A Dart Frog adapter is [planned](/guide/roadmap#later).
- Annotations go on top-level functions. From 0.3.0 they can also go on methods
  and on top-level variables that hold a closure. A closure passed inline to a
  router cannot carry an annotation.
- Models can be plain classes. From 0.3.0 axle also reads the annotations of
  `json_serializable`, `freezed`, and `dart_mappable`. See
  [Models and serialization](/models/).
- One spec per package. axle itself needs no `build_runner`, though your own
  model packages might.
- Security schemes, response headers, cookies, multiple media types, parameter
  constraints, and `oneOf` schemas are supported, with `anyOf` and `allOf` from
  0.3.0. Runtime enforcement, validation, and route discovery from router calls
  are not.

## Versions

axle is pre-1.0. The published packages are `0.2.0`; use `^0.2.0`. Features
marked **0.3.0** in these docs are implemented but not yet released, so use
`path:` or `git:` dependencies to try them. The [roadmap](/guide/roadmap) lists
what each version contains.
