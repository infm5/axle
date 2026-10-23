## 0.1.0

- Initial release.
- `axle init` project configuration with adapter-neutral setup guidance.
- `axle gen` analyzer-based generation of `openapi.json`, `openapi.yaml`, and a Dart constant.
- YAML is derived from the configured JSON output path; no duplicate path setting.
- `generate.output.ui` writes self-hosted Swagger UI assets into the project;
  defaults to `assets/swagger-ui`.
- `axle gen --check` validates JSON, YAML, UI assets, and the Dart constant.
- Minimal `axle.yaml` schema with strict validation and project-relative paths.
