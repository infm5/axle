# Troubleshooting

Error messages below are quoted from the CLI source. Exit codes: `64` usage,
`65` data (source violations), `70` software (internal), `78` config.

## Config errors (exit 78)

| Message | Cause | Fix |
| --- | --- | --- |
| `No axle.yaml found in <dir>. Run axle init … first.` | No config in project root | Run `axle init`, or pass `--config` / `--project` |
| `axle.yaml must contain a YAML map.` | Top level is not a map | Rewrite as mapping |
| `Unknown key 'x' in 'y'.` | Key outside the allowed set at any level (`openapi`/`info`/`generate`, `info.*`, `generate.*`, `generate.output.*`, `info.contact.*`, `info.license.*`, `security.*`, `tags[]`) | Delete it — `docs` and `swagger_ui_url` are runtime adapter concerns and are rejected by design |
| `` Only OpenAPI 3.1 documents are supported, but `openapi` is `x`. `` | Version outside `3.1.x` | Set `openapi: 3.1.0` |
| `` `info.title` / `info.version` is required … `` | Missing identity | Add both |
| `` `info.contact` must contain at least one of `name`, `url`, or `email`. `` | Empty contact map | Add one field or drop the block |
| `` `info.license.name` is required … `` | License block without a name | Add `name`, or drop the block |
| `` `generate.scan` must be a non-empty list of paths. `` | Missing/empty scan list | Add at least one directory or file |
| `Scan path 'x' does not exist.` | Scan entry missing on disk | Create it or correct the path |
| `` `generate.scan` / output path `x` must stay inside the project root. `` | `..` or absolute path escaping the root | Keep all paths inside the project |
| `` `generate.output.json` / `.ui` / `.dart` … `` required | Missing output setting (`ui` excepted — defaults to `assets/swagger-ui`) | Add the key |
| `Generated JSON, UI, and Dart outputs must point to different paths.` | Two outputs collide after normalization | Separate `json`, `ui`, `dart` |
| `` `generate.output.ui` must point to a directory, but `x` is not a directory. `` | `ui` path exists as a file | Point it at a directory |
| `axle.yaml already exists. Use --force to overwrite it.` | `init` without `--force` | Re-run with `--force` |
| `No pubspec.yaml found …` | `init` run outside a package | Run from the package root |
| `` `security.schemes.x.type` must be `http`, `apiKey`, `oauth2`, or `openIdConnect` `` | Unsupported scheme type | Use a supported type |
| `` `security.schemes.x.in` must be `header`, `query`, or `cookie` `` | Invalid API-key location | Fix `in` |
| `` `security.default` references unknown scheme `x` `` | Default lists an undefined scheme | Define it under `security.schemes` or remove it |
| `` `security.schemes.x.flows` must be a YAML map `` | OAuth2 scheme without flows | Add at least one flow |

## Source errors (exit 65)

Source errors print as `file:line:column: error: message`, one per line, so
editors can jump to the declaration. `axle gen` reports every problem it finds in
one run. Route errors point at the handler; DTO errors point at the field or
class. Config errors have no location.

| Message | Cause | Fix |
| --- | --- | --- |
| `@ApiRoute on f has no valid method.` / `has no path.` | Annotation failed constant evaluation | Check the `method:` / `path:` arguments are const-evaluable |
| `Could not evaluate an annotation on f: …` | Non-constant annotation argument | Keep annotation arguments compile-time constants |
| `Route paths must not be empty.` | Empty `path` | Provide a path |
| `Empty path parameter in '/users//x'.` | Empty `:param` or `{}` segment | Name the segment |
| `Duplicate route GET /x (from f).` | Same method + path twice | Merge or differentiate; use `ignore: true` on one |
| `Duplicate operationId 'x' for … Set a unique operationId …` | Repeated annotation sharing the default (function-name) ID | Set explicit `operationId` per annotation |
| `Path GET /x declares unused path parameters: id.` | `pathParams` entry with no matching `:id` / `{id}` segment | Align names |
| `Invalid response status 99 for GET /x.` | Status outside 100–599, or a response key that is not `default` or `1XX`–`5XX` | Use a real status, `ApiResponse.range`, or `ApiResponse.defaultResponse` |
| `Duplicate response status 200 for GET /x.` | The same status declared twice without adding a new media type | Merge into one `ApiResponse`, or give the second a different `contentTypes` (see [Several media types](/reference/annotations#several-media-types)) |
| `The request body of GET /x declares `text/plain` more than once.` | A media type listed in both `body` and `bodies`, or twice | List each media type once |
| `Wildcard route '/x/*' cannot be represented in OpenAPI. Add ignore: true …` | Glob segment | Add `ignore: true` to the annotation |
| `` Unsupported Dart type `x` in Foo.bar. `` | A record, function type, or unresolved type parameter | Replace it with a class, or hide the field with `@ApiProperty(ignore: true)` |
| `Generic class Foo expands without end.` | A generic class that instantiates itself with ever larger type arguments | Break the cycle with a concrete class |
| `Generic sealed class Foo cannot be expanded automatically.` | A sealed class with type parameters | List the subtypes with `@ApiSchema(oneOf: [...])` |
| `Sealed class Foo has no subtypes to describe.` | No subtype in the same library, or all are `ignore: true` | Add a subtype, or remove `sealed` |
| `@ApiSchema on Foo sets oneOf and anyOf.` | More than one of `oneOf`, `anyOf`, `allOf` | Keep one |
| `Foo declares a discriminator with allOf.` | A discriminator on an `allOf` schema | Put it on the base schema, with `oneOf` or `anyOf` |
| `Foo declares a discriminator without oneOf or anyOf.` | A discriminator on a plain class | Add `oneOf` or `anyOf`, or make the class `sealed` |
| `` Duplicate JSON property `x` in Foo. Check @JsonKey and @ApiProperty names. `` | `@JsonKey` / `@ApiProperty(name:)` collision | Rename one |
| `Missing 'type' in …` | Parameter/body/response annotation without a resolvable `Type` | Supply `type:` |
| `Style `x` is not valid for the … parameter` | `style:` is not allowed for the parameter's location | Use a style listed for that location in the [reference](/reference/annotations#style-and-explode) |
| `The … sets both `example` and `examples`.` | Both set on one parameter, body, or response | Keep one |
| `Scan path not found: x` | Scan entry vanished between config load and scan | Restore the path |
| `Could not start the Dart analyzer. Run dart pub get and try again. (…)` | Unresolved package config | Run `dart pub get` |
| `references unknown security scheme x` | Route uses a scheme not declared in `axle.yaml` | Add it under `security.schemes` or remove it |
| `has an empty security requirement` | An `ApiSecurityRequirement` has no schemes | Use `security: []` for a public route |
| `must declare at least one content type` | Empty `contentTypes` on a body/response | Remove the empty list or add a media type |

## Warnings

Warnings print as `axle: warning: …` and never change the exit code. They name the
class and property, but carry no file position yet.

| Message contains | Cause | Fix |
| --- | --- | --- |
| `Path GET /x has parameter {id} without an @ApiPathParam.` | A placeholder in the path with no declared parameter; axle used a string | Add `ApiPathParam('id', type: int)` |
| `Property Foo.bar uses a custom converter` | A `JsonConverter`, `@JsonKey(toJson:)`, or `@MappableField(hook:)` hides the JSON type | Add `@ApiProperty(type: ...)` |
| `Sealed class Foo becomes a oneOf without a discriminator` | Clients cannot tell the subtypes apart when their JSON overlaps | Add `@ApiSchema(discriminator: ApiDiscriminator(...))`. freezed unions get one automatically. |
| `Discriminator property `kind` of Foo is not declared by Bar` | A member of the union lacks the discriminator property | Add the field, or `@ApiProperty(name: 'kind')` |
| `Enum value Foo.bar … uses a non-string @JsonValue` | Only string enum values are supported | Use a string value |
| `Map keys in … are not Strings` | JSON object keys must be strings | Use `Map<String, T>` |
| `No Dart libraries found in …` | The scan path has no Dart files | Fix `generate.scan` |

## Stale artifacts

```
Generated files are out of date: openapi.json, lib/src/generated/openapi.g.dart.
Run `dart run axle_cli:axle gen`.
```

The committed artifacts do not match the annotated source. Regenerate and
commit the result. In CI, run `gen --check` instead of `gen`.

## Runtime pitfalls

- **Assets 404.** `swaggerUiDirectory` is resolved from the process working
  directory. Running the server from another directory breaks it; use an
  absolute path in deployments.
- **Empty asset mount.** Relic's and Serverpod's `mountSwaggerUiAssets` throw
  when the directory is missing or contains no files — run `axle gen` first.
- **`swaggerUiPath` collisions.** The asset prefix must not be `/`, the spec
  path, or the docs path; all three adapters throw `ArgumentError` otherwise.
- **Serverpod docs on the wrong port.** REST routes and docs are mounted on
  `pod.webServer` (example: `8082`), not the API server (`8090`). A `GET` to
  `/greeting` on the API port is the RPC endpoint and returns `400`.
- **Serverpod endpoint explorer.** `serverpod start` and Insights list
  `Endpoint` methods only. Web-server routes do not appear there; open the
  configured docs path on the web server port instead.
- **Serverpod generated file cleanup.** `serverpod generate` deletes unknown
  `.dart` files under `lib/src/generated/`. Keep `generate.output.dart` outside
  that directory, for example `lib/src/axle/openapi.g.dart`.
- **Port conflicts.** The Relic and Shelf examples read `PORT`, default `8080`.
  The Serverpod example uses API `8090`, Insights `8091`, and web `8082`.
- **Relic versions.** `axle_relic` accepts Relic `>=1.2.0 <3.0.0`. New projects
  use `relic: ^2.0.0-rc.2` until stable 2.x ships.

## Model pitfalls

- **`version solving failed` when adding `axle_cli` next to freezed.** freezed 3.x
  needs an older `analyzer` than `axle_cli`. Install the CLI globally instead:
  `dart pub global activate axle_cli`, then run `axle gen`. See
  [Models and serialization](/models/#installing-axle-next-to-your-code-generator).
- **Properties missing from a freezed or `dart_mappable` model.** Run
  `dart run build_runner build` first. axle reads the generated parts.
- **`build.yaml sets `field_rename: x`, which json_serializable does not accept`
  (and similar).** axle read an option in `build.yaml` that the builder would
  reject or ignore, or that is set to different values in two places. Fix the
  `build.yaml`; see [Options in `build.yaml`](/models/#options-in-build-yaml).
- **`build.yaml sets `ignore_unannotated: true`, which axle cannot apply to the
  freezed class`.** Set `@JsonSerializable(ignoreUnannotated: false)` on the
  class, or remove the option.

