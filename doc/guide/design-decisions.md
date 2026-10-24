# Design Decisions

Locked decisions from the v0.1 design pass, with rationale. These constrain
core, CLI, and adapter work — changes here require updating all three.

## Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Generation model | CLI + static analysis | AOT-safe; no runtime registry; predictable CI artifact. |
| Annotation location | Top-level handler functions and DTO classes | The analyzer resolves them reliably; closures cannot carry metadata. |
| Type mapping | Annotations carry `Type` literals plus nullable/optional flags | `UserDto?` is not valid Dart as a type literal. |
| Output | `openapi.json` + `openapi.yaml` + Swagger UI assets + Dart `const` | Tooling artifacts, self-hosted docs, AOT-safe serving. |
| Framework order | Relic, Shelf, then Serverpod | Concrete adapters validate the design before generalizing. |
| Config source | `axle.yaml` + annotations | YAML owns global contract identity; code owns route/type facts. |
| Swagger UI | Core HTML helper + adapter routes | Shared across adapters. |
| Example tests | None | The example is an integration demo; `gen --check` is the verification. |
| Security | Metadata only | Describe schemes and requirements; enforcement stays application-owned. |

## Why not build_runner

- Unnecessary for the CLI-first model.
- Adds `build.yaml`, generator lifecycle, and analyzer/`source_gen` version coupling.
- The CLI scans the same source and produces all artifacts.
- A future build_runner mode can reuse the analyzer layer if demand appears.

## Why not a runtime registry

- Relic, Shelf, and Serverpod web servers expose no public route list.
- No `dart:mirrors` in AOT.
- Runtime registration duplicates route metadata and drifts from the spec.

## Why not mixins for self-generating annotations

Dart has no macros or runtime reflection for this. A mixin can only:

- act as a marker (`class UserDto with ApiDto`) so the CLI infers fields by
  convention, or
- provide runtime behavior (`toJson`, validation), which the generator cannot execute.

Annotations are the correct mechanism for route metadata and explicit schema
overrides. A marker mixin for DTOs is a possible later convenience, not a
replacement.

## Consequences for contributors

- `axle_core` must never import a framework or HTTP type. Adapters translate
  `AxleDocs` values; they never push framework types into core.
- `axle_cli` must never import an adapter. Generation depends only on core's
  document model and annotations.
- Adapters must not require changes to core or the CLI. If a feature needs
  either, it belongs in core first (`AxleDocs`) or it is out of scope.
- New type shapes go through `schema_registry.dart` with explicit errors for
  unsupported forms — never silent `dynamic` fallbacks beyond the documented
  `dynamic`/`Object` rule.
