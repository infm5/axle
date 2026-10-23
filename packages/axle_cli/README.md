# axle_cli

The `axle` command-line interface.

## Install

As a dev dependency (recommended — `dart run` resolves it from your package):

```yaml
dev_dependencies:
  axle_cli: ^0.1.0
```

Or globally, once published:

```sh
dart pub global activate axle_cli
```

```sh
dart run axle_cli:axle init
dart run axle_cli:axle gen
dart run axle_cli:axle gen --check
```

`init` writes `axle.yaml` from `pubspec.yaml`. `gen` scans the configured source
directories with `package:analyzer` and writes:

- `generate.output.json` (default: `build/openapi.json`)
- the YAML artifact derived from that path (default: `build/openapi.yaml`)
- `generate.output.ui` Swagger UI assets (default: `assets/swagger-ui`)
- `generate.output.dart` (default: `lib/src/generated/openapi.g.dart`)

There is one spec path setting. The YAML path is derived by replacing the JSON
extension with `.yaml`, so JSON and YAML cannot drift apart in configuration.
The UI directory is self-contained and can be served directly by an axle adapter
or any static file server. The CLI bundles Swagger UI 5.34.0; its upstream
license and notice are included in `THIRD_PARTY_LICENSES/` and
`THIRD_PARTY_NOTICES.md`.

`axle.yaml` is the source of truth for global API identity and generator paths:

```yaml
openapi: 3.1.0
info:
  title: Todo API
  version: 0.1.0
generate:
  scan:
    - lib
  output:
    json: build/openapi.json
    ui: assets/swagger-ui
    dart: lib/src/generated/openapi.g.dart
```

The Dart artifact is a `const String axleOpenApiJson` that can be imported by the
server, so no file I/O is needed at runtime. No `servers`, `docs`,
`swagger_ui_url`, `tags`, or `security` blocks are accepted.

`init` does not assume a particular web framework or adapter. It prints generic
setup guidance; use the adapter README for framework-specific mounting.

Supported annotation features: path/query/header parameters, JSON request bodies,
responses, tags, summaries, descriptions, operation ids, deprecation, DTO schemas,
nested DTOs, enums, `List`/`Set`, `Map<String, T>`, nullability, `@JsonKey(name:)`,
and `@ApiProperty` overrides.

See the root [README](https://github.com/infm5/axle/blob/master/README.md) for the project overview and
[`docs/adapter-authoring.md`](https://github.com/infm5/axle/blob/master/docs/adapter-authoring.md) for the adapter
contract.
