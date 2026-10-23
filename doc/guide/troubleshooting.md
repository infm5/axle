# Troubleshooting

Error messages below are quoted from the CLI source. Exit codes: `64` usage,
`65` data (source violations), `70` software (internal), `78` config.

## Config errors (exit 78)

| Message | Cause | Fix |
| --- | --- | --- |
| `No axle.yaml found in <dir>. Run axle init … first.` | No config in project root | Run `axle init`, or pass `--config` / `--project` |
| `axle.yaml must contain a YAML map.` | Top level is not a map | Rewrite as mapping |
| `Unknown key 'x' in 'y'.` | Key outside the allowed set at any level (`openapi`/`info`/`generate`, `info.*`, `generate.*`, `generate.output.*`, `info.contact.*`, `info.license.*`) | Delete it — `servers`, `docs`, `swagger_ui_url`, `tags`, `security` are all rejected by design |
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

## Source errors (exit 65)

| Message | Cause | Fix |
| --- | --- | --- |
| `@ApiRoute on f has no valid method.` / `has no path.` | Annotation failed constant evaluation | Check the `method:` / `path:` arguments are const-evaluable |
| `Could not evaluate an annotation on f: …` | Non-constant annotation argument | Keep annotation arguments compile-time constants |
| `Route paths must not be empty.` | Empty `path` | Provide a path |
| `Empty path parameter in '/users//x'.` | Empty `:param` or `{}` segment | Name the segment |
| `Duplicate route GET /x (from f).` | Same method + path twice | Merge or differentiate; use `ignore: true` on one |
| `Duplicate operationId 'x' for … Set a unique operationId …` | Repeated annotation sharing the default (function-name) ID | Set explicit `operationId` per annotation |
| `Path GET /x declares unused path parameters: id.` | `pathParams` entry with no matching `:id` / `{id}` segment | Align names |
| `Invalid response status 99 for GET /x.` | Status outside the valid range/shape | Use a real status code |
| `Duplicate response status 200 for GET /x.` | Same status twice on one operation | Merge into one `ApiResponse` |
| `Wildcard route '/x/*' cannot be represented in OpenAPI. Add ignore: true …` | Glob segment | Add `ignore: true` to the annotation |
| `Generic classes are not supported: Foo. Use a concrete DTO class instead.` | Type parameter in a DTO | Concretize the class |
| `` Duplicate JSON property `x` in Foo. Check @JsonKey and @ApiProperty names. `` | `@JsonKey` / `@ApiProperty(name:)` collision | Rename one |
| `Missing 'type' in …` | Parameter/body/response annotation without a resolvable `Type` | Supply `type:` |
| `Scan path not found: x` | Scan entry vanished between config load and scan | Restore the path |
| `Could not start the Dart analyzer. Run dart pub get and try again. (…)` | Unresolved package config | Run `dart pub get` |

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
- **Relic prerelease.** Pin `relic: ^2.0.0-rc.2` until stable 2.x ships.
