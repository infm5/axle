# Troubleshooting and Validation

## First checks

Run from the project root:

```sh
dart pub get
dart run axle_cli:axle gen
dart run axle_cli:axle gen --check
dart analyze
```

Inspect the generated `openapi.json` before changing code:

```sh
jq '.info, .paths | keys, .components.securitySchemes' openapi.json
```

## Common errors

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `0 paths` generated | Scan path misses the handlers, or annotations are on inline closures, or on methods with axle 0.2.0 | Fix `generate.scan`; move `@ApiRoute` to a top-level function (methods and top-level variables need 0.3.0) |
| `No Dart libraries found` | `generate.scan` points at a missing/empty directory | Use the actual `lib` or source directory |
| `Unknown key 'docs'` / `'swagger_ui_url'` | Runtime adapter options were added to `axle.yaml` | Remove them; pass options to the adapter |
| `references unknown security scheme` | Route references a scheme not under `security.schemes` | Define the scheme or remove the requirement |
| `security.default references unknown scheme` | Global default name typo | Fix the YAML name |
| `must declare at least one content type` | Empty `contentTypes` on a body/response | Remove the empty list or add a media type |
| `gen --check` fails | Generated files are stale | Run `axle gen` and commit the artifacts |
| `dart analyze` fails after adding annotations | Missing dependency/import or wrong handler signature | Check the adapter package and import |
| `openapi.json` exists but Swagger UI is blank | Wrong spec path, missing assets, or path collision | Check `specPath`, `swaggerUiPath`, and assets |
| Docs route returns `404` | Serverpod docs are on the web-server port, or path mismatch | Open the `pod.webServer` port and configured docs path |
| Docs work on `/docs` but assets 404 | `swaggerUiDirectory` is missing or stale | Run `axle gen`; serve the generated asset directory |
| Auth button missing | No `securitySchemes` in the document | Add the scheme in `axle.yaml` and regenerate |
| Every route inherited security unexpectedly | Global `security.default` is set | Override with `security: []` where appropriate |

## Framework-specific checks

### Relic

- Use `^2.0.0-rc.2` until Relic 2 is stable.
- `RelicApp.mountAxleDocs` must run before `app.serve()`.
- Local asset paths resolve from the process working directory.

### Shelf

- Put the docs handler before the router:
  `Cascade().add(docs).add(router.call).handler`. Shelf treats `404` as
  “not handled,” so router-first can swallow an intentional API `404`.
- `axleDocsHandler` returns `404` for non-GET and unrelated paths.
- `shelf_router` uses `<id>` path syntax. Use it in the shared annotation/route
  constant; axle normalizes it to `{id}`.
- `shelf_static` may reject traversal/symlink paths; keep assets inside the
  generated directory.

### Serverpod

- Docs use `pod.webServer`, not the API server.
- `serverpod start`/Insights list Endpoint methods, not web-server `Route`s.
- Annotate a top-level delegate and call it from `Route.handleCall`. With axle
  0.3.0 you can annotate `handleCall` itself.
- Keep the annotation path and `addRoute` path in one constant.
- API-server `Endpoint` RPC methods are not documented by this adapter.

## OpenAPI validation

Validate the generated spec with Redocly or another OpenAPI 3.1 validator. The
default axle config intentionally omits `servers` and may omit a license, while
the project may mix public and protected operations:

```sh
npx --yes @redocly/cli@2.71.0 lint openapi.json \
  --skip-rule=no-empty-servers \
  --skip-rule=security-defined \
  --skip-rule=operation-4xx-response \
  --skip-rule=info-license
```

Those skips are style choices, not correctness bypasses:

- `no-empty-servers`: the framework may own the origin.
- `security-defined`: public and protected routes can intentionally coexist.
- `operation-4xx-response`: not every operation needs a documented 4xx.
- `info-license`: license metadata may be private or not yet chosen.

Do not skip schema, `$ref`, or syntax errors. Those indicate a broken contract.

## CI

A reliable CI check is:

```sh
dart pub get
dart analyze
dart run axle_cli:axle gen --check
dart test
```

Add the OpenAPI linter as a separate step so a schema regression doesn't get
hidden behind Dart tests.

## Do not

- Hand-edit generated `openapi.json`, `openapi.yaml`, or `openapi.g.dart`.
- Add security metadata for enforcement that does not exist.
- Add media types or headers that the server cannot produce.
- Put handlers inside closures or classes and expect discovery.
- Commit stale generated artifacts after changing annotations.
