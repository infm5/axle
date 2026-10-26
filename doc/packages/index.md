# Packages

axle is five packages with one dependency rule: **everything points at core,
nothing points back.**

```
axle_core
   ^        ^          ^           ^
   |        |          |           |
axle_cli  axle_relic  axle_shelf  axle_serverpod
              ^          ^           ^
              |          |           |
            apps       apps        apps
```

| Package | Role | Depends on |
| --- | --- | --- |
| [axle_core](/packages/core) | Annotations, OpenAPI 3.1 document model, `AxleDocs`, Swagger UI HTML | Nothing (no framework, no runtime deps) |
| [axle_cli](/packages/cli) | `axle init` / `axle gen`, analyzer scanning, JSON + YAML + Dart + UI-asset artifacts | `axle_core` only — never an adapter |
| [axle_relic](/packages/relic) | Relic adapter: `mountAxleDocs`, standalone handlers, local assets | `axle_core` (+ `relic`); re-exports core |
| [axle_shelf](/packages/shelf) | Shelf adapter: `axleDocsHandler`, standalone handlers, local assets | `axle_core` (+ `shelf`); re-exports core |
| [axle_serverpod](/packages/serverpod) | Serverpod adapter: `WebServer.mountAxleDocs`, web-server routes, local assets | `axle_core` (+ `serverpod`); re-exports core |

Each page in this section follows the same format:

1. **What it is** — the package's single responsibility.
2. **Install** — how it enters `pubspec.yaml`.
3. **API** — the surface you actually call, with defaults.
4. **Examples** — minimal working snippets.
5. **Boundaries** — what the package explicitly does not do.

## Adapter comparison

All three adapters expose the same `AxleDocs` paths, title, cache, and asset
options. The differences are framework-shaped:

| Concern | Relic | Shelf | Serverpod |
| --- | --- | --- | --- |
| Mount | `app.mountAxleDocs(...)` | `axleDocsHandler(...)` | `pod.webServer.mountAxleDocs(...)` |
| Standalone pieces | `openApiJsonHandler`, `swaggerUiHandler` | `openApiJsonHandler`, `swaggerUiHandler` | `AxleOpenApiRoute`, `AxleDocsRoute` |
| Assets | `mountSwaggerUiAssets(dir)` | `swaggerUiAssetsHandler(dir)` | `mountSwaggerUiAssets(dir)` |
| Runtime surface | Any Relic route | Any Shelf handler | Serverpod web-server `Route` only |
| Serverpod RPC | — | — | Not documented; endpoints are out of scope |

The Serverpod adapter is the narrowest: it serves docs from the web server and
documents ordinary `Route`s. It does not describe API-server `Endpoint` methods.
See [axle_serverpod](/packages/serverpod) for the full boundary and mounting
example.

## Versioning

All five packages are versioned independently but currently share `0.2.0`.
Adapters depend on a compatible `axle_core` range (e.g. `^0.2.0`). Core is the
stable contract, and adapters must never force users to match the CLI version.
Dart floors are intentionally split, so an adapter does not inherit the CLI's:

| Package | Minimum Dart |
| --- | --- |
| `axle_core` | 3.7 |
| `axle_shelf` | 3.9 |
| `axle_relic` | 3.10 |
| `axle_cli` | 3.11 |
| `axle_serverpod` | 3.12 |

## Which Packages Does an App Need?

- **Relic app:** `axle_relic` (runtime) + `axle_cli` (dev). Core comes along
  via re-export.
- **Shelf app:** `axle_shelf` (runtime) + `axle_cli` (dev). Same re-export story.
- **Serverpod app:** `axle_serverpod` (runtime) + `axle_cli` (dev). Docs are
  served on the Serverpod web server port.
- **Another framework:** `axle_core` (runtime) + `axle_cli` (dev) + your own
  adapter built on `AxleDocs`. See [Building an Adapter](/adapters/building-an-adapter).

If the app uses freezed 3.x, install `axle_cli` globally instead of as a dev
dependency; see
[Models and serialization](/models/#installing-axle-next-to-your-code-generator).
