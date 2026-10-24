## 0.2.0

- Added `security` configuration with HTTP, API key, OAuth2, and OpenID Connect
  schemes plus default requirements.
- Added route-level `@ApiRoute(security: ...)` and public overrides.
- Added response headers, cookie parameters, multiple media types, and multipart
  body generation.
- Added parameter and property constraints.
- Added `oneOf` discriminator generation through `@ApiSchema`.
- Added global tags, external docs, terms of service, and optional servers.

## 0.1.0

- Initial release.
- `axle init` project configuration with adapter-neutral setup guidance.
- `axle gen` analyzer-based generation of `openapi.json`, `openapi.yaml`, and a Dart constant.
- YAML is derived from the configured JSON output path; no duplicate path setting.
- `generate.output.ui` writes self-hosted Swagger UI assets into the project;
  defaults to `assets/swagger-ui`.
- `axle gen --check` validates JSON, YAML, UI assets, and the Dart constant.
- Minimal `axle.yaml` schema with strict validation and project-relative paths.
