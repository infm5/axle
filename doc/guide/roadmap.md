# Roadmap & Status

Phases 0–1 are implemented, Phase 2 is partially implemented, and Phases 3–5
are planned. Exit criteria are quoted from the design doc.

## Done

**Phase 0 — Config cleanup and example relocation.**

- `axle.yaml` holds only `openapi`, `info`, `generate.scan`, `generate.output`.
- `servers`, `docs`, `swagger_ui_url`, `tags`, `security` rejected.
- `init` reads `pubspec.yaml` once to seed identity, then never again.
- Docs title derived from the spec's `info.title`.
- Relic Todo example built; workspace + CI + READMEs updated.

**Phase 2 (partial, shipped early) — Framework adapters.**

- `AxleDocs` extracted from `axle_relic` into core.
- `axle_shelf` added; it serves the same generated artifact as `axle_relic`
  with no core/CLI changes.
- `axle_serverpod` added for Serverpod 4 web-server routes, with a Docker-free
  example and generated `Greeting` schema.
- Local Swagger UI assets generated into `generate.output.ui`.
- `axle init` is adapter-neutral; path deps replaced with version constraints;
  pub metadata, `.pubignore` files, tag-driven OIDC publish workflows, and MIT
  licenses added.

## Current

**Phase 1 — Contract quality.**

- Source locations in generator errors.
- Strict schema validation and duplicate detection.
- OpenAPI 3.1 structural validation in CI (Redocly or a JSON Schema validator).
- Response headers, cookie parameters, multiple media types.
- `oneOf` / discriminator design for sealed classes.
- Contract diff tooling / CI artifact comparison.

Exit: generated spec validates against OpenAPI 3.1; errors point at the
offending Dart symbol; schema coverage documented.

## Planned

**Phase 2 (remainder).** `axle_dart_frog`, serving the same artifact with no
core/CLI changes. The Serverpod adapter is implemented for Serverpod 4 web
routes; RPC `Endpoint` documentation remains out of scope.

**Phase 3 — Security metadata.** Scheme definition API, route-level security
annotations, global default, validation against defined schemes. Application
middleware stays application-owned. Exit: security refs validate and match an
actually-protected example app. Design hook:

- `@ApiRoute(security: ['bearerAuth'])` on protected handlers.
- `security: []` marks one operation public.
- `null` inherits a global default.
- `axle gen` validates every referenced scheme exists.

**Phase 4 — Distribution.** Publish `axle_core`, `axle_cli`, `axle_relic`,
`axle_shelf`, and `axle_serverpod` to pub.dev; document supported
Dart/analyzer/framework versions. Exit: installable from pub.dev; example works
from a clean checkout.

**Phase 5 — Advanced tooling.** Watch mode, contract lint/diff, mock server
from spec/examples, `transformJson` serving hook, multiple specs per package
(only on real demand).

## Open Decisions

1. Optional advanced `servers` support for proxied deployments.
2. Top-level tag descriptions vs operation tags only.
3. Security schemes as annotations vs adapter/config registries.
4. Config schema version for future migrations.
5. A future build_runner mode reusing the CLI scanner.
6. Example as workspace member vs standalone package with its own lockfile.
7. Multiple specs per package.

Current positions: no servers, no top-level tags, security later, no
build_runner, `AxleDocs` as the stable contract, workspace-member examples, one
spec per package.
