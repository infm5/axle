# Roadmap and Status

axle is pre-1.0. This page lists what each version contains, and what is planned
after that. The per-package changelogs
(`CHANGELOG.md` in each package) are the exact record; this page groups them by
theme.

| Version | Status | Date | Focus |
| --- | --- | --- | --- |
| [0.1.0](#_0-1-0) | Released | 2026-10-23 | Core, CLI, Relic and Shelf adapters |
| [0.2.0](#_0-2-0) | Released | 2026-10-24 | Security, richer contracts, Serverpod adapter |
| [0.3.0](#_0-3-0) | Released | — | Models, generics and unions, response keys, diagnostics |
| [Later](#later) | Planned | — | Dart Frog, contract diff, more OpenAPI objects |

All five packages share the version number; `axle_serverpod` started at `0.2.0`.
Each package changelog lists the changes in 0.3.0.

## 0.1.0

The first release: generate a spec from annotated Dart, and serve it.

**Generate**

- `axle init` writes `axle.yaml`, seeding the title and version from
  `pubspec.yaml` once.
- `axle gen` reads annotated handlers and DTO classes with `package:analyzer` and
  writes `openapi.json`, `openapi.yaml`, a `const String axleOpenApiJson`, and a
  vendored Swagger UI (5.34.0) into the project.
- `axle gen --check` fails when any generated file is stale, for CI.
- DTO schemas are inferred from public fields: nested classes, enums, lists,
  sets, maps, nullability, `DateTime`, `Uri`, `Duration`, `BigInt`, and byte
  data. `@JsonKey(name:)` and `@ApiProperty` override names and metadata.
  Output ordering is deterministic.
- `axle.yaml` is validated strictly: unknown keys are errors, paths must stay
  inside the project, and `docs` and `swagger_ui_url` are rejected because they
  belong to the runtime adapter.

**Serve**

- `AxleDocs` in `axle_core` is the shared contract that adapters serve: paths,
  title, cache headers, and the Swagger UI shell.
- `axle_relic` (`mountAxleDocs`) and `axle_shelf` (`axleDocsHandler`) serve the
  same generated artifact, with optional local Swagger UI assets.
- Runnable Todo examples for Relic and Shelf.

**Project**

- MIT license, pub.dev metadata, and tag-driven publishing workflows that use
  GitHub OIDC.

## 0.2.0

A richer contract, security metadata, and a third adapter.

**Contract**

- Security schemes (`http`, `apiKey`, `oauth2`, `openIdConnect`), a document-wide
  default, per-route requirements and scopes, and `security: []` for public
  routes. Every referenced scheme is validated. axle describes security; the
  application still enforces it.
- Response headers, cookie parameters, multiple request and response media types,
  and multipart bodies with binary file properties.
- Parameter and property constraints: formats, enums, numeric bounds, string
  lengths, and patterns.
- `oneOf` schemas with discriminators, declared through `@ApiSchema`.
- Global tags, external documentation, terms of service, and optional `servers`.

**Adapters**

- `axle_serverpod` serves docs from the web server of a Serverpod 4 app and
  documents its web-server `Route`s. API-server `Endpoint` RPC is out of scope.

**Examples, docs, and tooling**

- The Relic and Shelf examples exercise the contract features against live
  handlers, including real API key checks, content negotiation, and multipart
  uploads. A Docker-free Serverpod example was added.
- The documentation site and the `axle-openapi-setup` agent skill.

## 0.3.0

It makes axle read the models people actually write, covers more
Dart shapes, and reports problems precisely.

**Models and serialization**

- `json_serializable`: class-level `fieldRename`, `@JsonEnum(fieldRename:)`, and
  string `@JsonValue`.
- `freezed`: data classes are read from their factory parameters, with
  `@Default`, `@JsonKey`, and `fieldRename`. Sealed unions become `oneOf` with the
  union key as discriminator, `@FreezedUnionValue` values, and the key pinned on
  each variant.
- `dart_mappable`: `@MappableClass(caseStyle:)`, `@MappableField(key:)`,
  `@MappableEnum`, and `@MappableValue`.
- Custom converters: the schema uses the JSON type of a `JsonConverter` or of
  `@JsonKey(toJson:)`. axle warns when that type is unknown, and
  `@ApiProperty(type:)` states it explicitly.
- `build.yaml` options that change the JSON are read: `field_rename` and
  `ignore_unannotated` for `json_serializable`, and `caseStyle` and
  `enumCaseStyle` for `dart_mappable_builder`. An invalid, ignored, or
  conflicting value fails with exit code 65 instead of producing a spec that
  disagrees with the server. `@JsonSerializable(ignoreUnannotated:)` is read too.

**Schemas**

- Generic DTOs: each instantiation is its own schema, so `Page<UserDto>` becomes
  `Page_UserDto`.
- Sealed classes become `oneOf` of their subtypes. axle warns when a union has no
  discriminator, or when a member does not declare the discriminator property.
- `@ApiSchema(allOf:)` and `@ApiSchema(anyOf:)`, next to `oneOf`.

**Routes and responses**

- `@ApiRoute` works on class and mixin methods and on top-level variables that
  hold a closure, not only on top-level functions. Methods default to the
  operation id `Class_method`.
- New response shortcuts for 401, 403, 409, 422, and 429, plus `default` and range
  (`4XX`) responses. Shared error lists are a const list spread into
  `responses`.
- Parameter `style` and `explode`, validated per location.
- Named `examples` on parameters, request bodies, and responses.
- One status can return several media types with a schema for each (JSON, CSV,
  XML, and so on), and `bodies:` accepts several request media types the same
  way. `default` and range responses take `contentTypes:` and `headers:`, so they
  can be `application/problem+json`.
- Raw bytes are `format: binary` under any media type except JSON, so downloads
  such as `image/png` and `application/pdf` are described correctly.
- Constraints on a `List<T>` property describe its items, which makes
  multi-file uploads (`format: binary` on each file) possible.
- Response header examples reach the spec.

**Diagnostics**

- Errors print as `file:line:column: error: message`, and one run reports every
  problem instead of stopping at the first. A broken DTO used by several routes
  is reported once.
- `checkShelfRoutes` (and the framework-neutral `checkDocumentedRoutes`) test
  that every path in the spec reaches a handler, so an `@ApiRoute` path and its
  router registration cannot drift apart unnoticed. See
  [Keeping paths in sync](/guide/keeping-paths-in-sync).
- Fixed a crash when `analysis_options.yaml` excludes generated files such as
  `*.mapper.dart` or `*.freezed.dart`.

**Adapters**

- `axle_relic` accepts Relic `>=1.2.0 <3.0.0`; its tests pass on Relic 1.2.0 and
  on 2.0.0-rc.2.

**Examples, docs, and tooling**

- New runnable examples for `dart_mappable` and `freezed`; the Shelf example uses
  `json_serializable`. Each checks the spec against the real JSON.
- A showcase API with 50 operations, 20 media types, and 37 headers, tested
  against its own generated spec.
- A Models section in the docs, a comparison with alternatives, and
  `CONTRIBUTING.md`.
- Golden specs for each supported Dart shape, linted with Redocly in CI together
  with the example specs.

**Upgrade notes**

- A `build.yaml` that sets `field_rename`, `ignore_unannotated`, `caseStyle`, or
  `enumCaseStyle` now changes the spec, as it already changed your server's JSON.
  Regenerate and review the diff.
- Generic classes no longer fail generation.
- Sealed classes now produce a `oneOf`. Existing projects may see new warnings
  about missing discriminators or custom converters.
- `axle_cli` does not resolve in the same `pubspec.yaml` as freezed 3.x. Install
  it globally: `dart pub global activate axle_cli`. See
  [Models and serialization](/models/#installing-axle-next-to-your-code-generator).

## Later

Nothing here has a release number yet. Items marked *on request* wait for a real
need.

**Adapters**

- `axle_dart_frog`. Dart Frog derives paths from file names, so the generator
  would take the path from the route file and the method from the annotation.
  It would serve the same artifact with no change to core or the CLI.

**Contract coverage**

- Specification extensions (`x-` keys), on operations, schemas, and the document.
  *On request.*
- Webhooks and callbacks. *On request.* Links are unlikely.
- Locations on warnings, which today carry only the symbol name.
- `info.summary`, server variables, and `uniqueItems` for a `Set`.
- freezed `unionValueCase`, dart_mappable discriminators, non-string
  `@JsonValue`, `@JsonEnum(valueField:)`, and generic sealed classes.

**Tooling**

- Contract diff: compare two specs and flag breaking changes in CI.
- Watch mode for `axle gen`.
- A mock server generated from the spec and its examples.
- A `transformJson` hook for serving.
- Tag filtering, and multiple specs per package. *On request.*

**Out of scope**

- Documenting Serverpod `Endpoint` RPC. It speaks a binary protocol, not REST.
- Runtime request validation, response serialization, and auth enforcement. These
  stay with the server framework.

## Open decisions

1. Whether to add a version field to `axle.yaml` for future migrations.
2. Whether a `build_runner` mode that reuses the CLI scanner is worth the
   `analyzer` coupling. The [freezed conflict](/models/#installing-axle-next-to-your-code-generator)
   shows that cost.
3. Whether to infer `allOf` from class inheritance. Today it is explicit.
4. Whether watch mode, tag filtering, and multiple specs justify their weight.

Current positions: `allOf`, `anyOf`, and `oneOf` are explicit, while sealed
classes become `oneOf` automatically; one spec per package; security metadata
without enforcement; no `build_runner` for axle itself; `AxleDocs` as the stable
adapter contract.
