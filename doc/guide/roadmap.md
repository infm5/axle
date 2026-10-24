# Roadmap & Status

Phases 0–3 are substantially implemented, Phase 2 is partially implemented,
and Phases 4–5 are planned. Phase 1 still has validation and contract-diff work.
Exit criteria are quoted from the design doc.

## Done

**Phase 0 — Config cleanup and example relocation.**

- `axle.yaml` owns `openapi`, `info`, optional global metadata, and
  `generate.scan` / `generate.output`.
- `docs` and `swagger_ui_url` stay runtime adapter concerns and are rejected.
- `init` reads `pubspec.yaml` once to seed identity, then never again.
- Docs title derived from the spec's `info.title`.
- Relic Todo example built; workspace + CI + READMEs updated.

**0.2.0 release line (2026-10-24).**

- Security schemes and requirements: `http`, `apiKey`, `oauth2`,
  `openIdConnect`; global default and per-route overrides.
- Response headers, cookie parameters, multiple media types, and
  multipart/binary uploads.
- Parameter and property validation constraints.
- Explicit `oneOf` discriminators through `@ApiSchema`.
- Global tags, external docs, terms of service, and optional `servers`.
- Relic and Shelf examples exercise the new contract features against live
  handlers.

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

- [x] Strict schema validation and duplicate detection.
- [x] Response headers, cookie parameters, and multiple media types.
- [x] Explicit `oneOf` / discriminator schemas.
- [ ] Source locations in generator errors.
- [ ] OpenAPI 3.1 structural validation in CI (Redocly or a JSON Schema validator).
- [ ] Contract diff tooling / CI artifact comparison.

Exit: generated spec validates against OpenAPI 3.1; errors point at the
offending Dart symbol; schema coverage documented.

## Planned

**Phase 2 (remainder).** `axle_dart_frog`, serving the same artifact with no
core/CLI changes. The Serverpod adapter is implemented for Serverpod 4 web
routes; RPC `Endpoint` documentation remains out of scope.

**Phase 3 — Security metadata (done).** Scheme definitions, route-level
requirements, a global default, and reference validation are implemented.
Application middleware still owns enforcement.

- `security.schemes` in `axle.yaml` defines reusable schemes.
- `@ApiRoute(security: [ApiSecurityRequirement([...])])` protects operations.
- `security: []` marks one operation public.
- `null` inherits the document default.
- `axle gen` validates every referenced scheme exists.

**Phase 4 — Distribution.** `0.2.0` is prepared across `axle_core`, `axle_cli`,
`axle_relic`, `axle_shelf`, and `axle_serverpod`. Publish core first, then the
adapters; `axle_serverpod` needs its first manual publication. Exit: installable
from pub.dev; example works from a clean checkout.

**Phase 5 — Advanced tooling.** Watch mode, contract lint/diff, mock server
from spec/examples, `transformJson` serving hook, multiple specs per package
(only on real demand).

## Open Decisions

1. Automatic `allOf`/`anyOf` and sealed-hierarchy inference.
2. Watch mode, tag filtering, and multiple specs per package.
3. Contract diffing and mock generation.
4. Config schema version for future migrations.
5. A future build_runner mode reusing the CLI scanner.
6. Example as workspace member vs standalone package with its own lockfile.

Current positions: explicit `oneOf` only, one spec per package by default,
security metadata without enforcement, no build_runner, `AxleDocs` as the stable
contract.
