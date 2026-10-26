# Alternatives

axle is not the only way to document a Dart server. This page compares it with
the packages for the same job. The facts about the other packages come from
their pub.dev pages on 2026-10-24; check them before you decide, because these
packages move. Items marked * are in axle 0.3.0, which is not released yet.

| | axle | [shelf_open_api_generator](https://pub.dev/packages/shelf_open_api_generator) | [dart_frog_open_api](https://pub.dev/packages/dart_frog_open_api) | [dart_frog_swagger](https://pub.dev/packages/dart_frog_swagger) |
| --- | --- | --- | --- | --- |
| Frameworks | Relic, Shelf, Serverpod web routes | Shelf | Dart Frog | Dart Frog |
| How it works | CLI reads your source with `package:analyzer` | `build_runner` generator | `build_runner` (zto DTOs) plus a per-route fluent API | CLI scan of `@Route` annotations |
| OpenAPI version | 3.1 | v3 (version not stated) | 3.0 | not stated |
| Security schemes | `http`, `apiKey`, `oauth2`, `openIdConnect` | Partial | Docs access guard | Not documented |
| `oneOf` / `allOf` / `anyOf` | `oneOf` with discriminators; `allOf`, `anyOf`, and sealed classes* | `allOf`, `oneOf`, discriminator; no `anyOf` | Not documented | Not documented |
| Model packages | `json_serializable`*, `freezed`*, `dart_mappable`*, plain classes | `json_serializable` | `zto` DTOs | Not documented |
| Swagger UI | Self-hosted assets | Not documented | Swagger UI and Scalar | Yes |
| Extras | `gen --check` for CI, AOT-safe `const` spec, agent skill | `shelf_routing` integration | Postman and Bruno export | None |

## Where the others are ahead

- **Dart Frog.** axle has no Dart Frog adapter yet. If you use Dart Frog today,
  `dart_frog_open_api` or `dart_frog_swagger` is the practical choice.
- **Reading routes from the router.** `shelf_open_api_generator` can type routes
  through `shelf_routing`, so you do not repeat the path in an annotation. With
  axle you write the path in `@ApiRoute`; share it through a constant.
- **Maturity.** axle is young. The packages above have been published longer.

## Where axle differs

- **No `build_runner` for axle itself.** `axle gen` is a single command and needs
  no `build.yaml`. The cost is an `analyzer` dependency, which is why freezed 3.x
  projects install the CLI globally; see
  [Models and serialization](/models/#installing-axle-next-to-your-code-generator).
- **OpenAPI 3.1** with `type: [..., "null"]` nullability and JSON Schema 2020-12.
- **A staleness check.** `axle gen --check` fails CI when the committed spec is
  out of date.
- **One core, thin adapters.** The adapter contract is small enough to write for
  another framework; see [Building an adapter](../adapters/building-an-adapter).

If you have used one of these and something is wrong here, please
[open an issue](https://github.com/infm5/axle/issues).
