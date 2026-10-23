# Packages

axle is four packages with one dependency rule: **everything points at core,
nothing points back.**

```
axle_core
   ^        ^          ^
   |        |          |
axle_cli  axle_relic  axle_shelf
              ^          ^
              |          |
            apps       apps
```

| Package | Role | Depends on |
| --- | --- | --- |
| [axle_core](/packages/core) | Annotations, OpenAPI 3.1 document model, `AxleDocs`, Swagger UI HTML | Nothing (no framework, no runtime deps) |
| [axle_cli](/packages/cli) | `axle init` / `axle gen`, analyzer scanning, JSON + YAML + Dart + UI-asset artifacts | `axle_core` only — never an adapter |
| [axle_relic](/packages/relic) | Relic adapter: `mountAxleDocs`, standalone handlers, local assets | `axle_core` (+ `relic`); re-exports core |
| [axle_shelf](/packages/shelf) | Shelf adapter: `axleDocsHandler`, standalone handlers, local assets | `axle_core` (+ `shelf`); re-exports core |

Each page in this section follows the same format:

1. **What it is** — the package's single responsibility.
2. **Install** — how it enters `pubspec.yaml`.
3. **API** — the surface you actually call, with defaults.
4. **Examples** — minimal working snippets.
5. **Boundaries** — what the package explicitly does not do.

## Versioning

All four packages are versioned independently but currently share `0.1.0`.
Adapters depend on a compatible `axle_core` range (e.g. `^0.1.0`) — core is the
stable contract, and adapters must never force users to match the CLI version.
Dart floors are intentionally split: core supports Dart 3.7+, while the
analyzer-based CLI has the highest floor.

## Which Packages Does an App Need?

- **Relic app:** `axle_relic` (runtime) + `axle_cli` (dev). Core comes along
  via re-export.
- **Shelf app:** `axle_shelf` (runtime) + `axle_cli` (dev). Same re-export story.
- **Another framework:** `axle_core` (runtime) + `axle_cli` (dev) + your own
  adapter built on `AxleDocs`. See [Building an Adapter](/adapters/building-an-adapter).
