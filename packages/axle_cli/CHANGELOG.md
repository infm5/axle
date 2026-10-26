## 0.3.0

- Generator errors carry `file:line:column` locations, and one run reports every
  problem instead of stopping at the first. A broken DTO used by several routes
  is reported once.
- `@ApiRoute` is discovered on class and mixin methods and on top-level
  variables that hold a closure, in addition to top-level functions.
- Generic DTOs: each instantiation becomes its own schema (`Page<UserDto>` is
  `Page_UserDto`). Generic classes no longer fail generation.
- Sealed classes become `oneOf` of their subtypes. axle warns about a sealed
  union without a discriminator, and about a member that does not declare the
  discriminator property.
- `@ApiSchema(allOf:, anyOf:)` is generated, next to `oneOf`.
- `json_serializable`: class-level `@JsonSerializable(fieldRename:)` and
  `ignoreUnannotated:`, `@JsonEnum(fieldRename:)`, and string `@JsonValue(...)`.
- `json_serializable`: the schema uses the JSON type of a `JsonConverter` or of
  `@JsonKey(toJson:)`, and warns when that type cannot be determined.
  `@ApiProperty(type:)` states it explicitly.
- `freezed`: data classes are read from their factory parameters, with
  `@Default`, `@JsonKey`, and `fieldRename`. A factory's own
  `@JsonSerializable` wins over the class and the project default, even
  `FieldRename.none`.
- `freezed`: sealed unions become `oneOf` with the union key as discriminator,
  `@FreezedUnionValue` values, and the key pinned on each variant.
- `dart_mappable`: `@MappableClass(caseStyle:)`, `@MappableField(key:)`,
  `@MappableEnum(caseStyle:)`, and `@MappableValue`.
- Reads the root `build.yaml` for the options that change the JSON:
  `field_rename` and `ignore_unannotated` for `json_serializable` (and freezed
  classes with a `fromJson` factory), and `caseStyle` and `enumCaseStyle` for
  `dart_mappable_builder`. A class's own annotation still wins. Before, these
  options changed the server's JSON without changing the spec.
- Invalid `build.yaml` options fail with exit code 65: an invalid value, a value
  the builder ignores (`caseStyle: upperSnakeCase`), the same option set two
  ways, and `ignore_unannotated: true` together with freezed `fromJson` classes.
- `default` and range (`4XX`) response keys, the 401, 403, 409, 422, and 429
  shortcuts, parameter `style` and `explode` (validated per location), and
  named `examples` are generated. A const list spread into `responses` shares
  error responses across routes.
- Responses that share a status are merged by media type, so one status can
  return JSON, CSV, and XML with a schema for each. A repeat that adds no new
  media type is still a duplicate error. `ApiRoute(bodies:)` merges several
  request bodies the same way.
- `Uint8List` and `ByteData` bodies and responses are `format: binary` under any
  media type except JSON, where they stay base64 (`format: byte`). Before, raw
  downloads such as `image/png` were documented as base64.
- Constraints on a `List<T>` property describe its items.
- Response header examples are written to the spec.
- Fixed a crash when `analysis_options.yaml` excludes generated files such as
  `*.mapper.dart` or `*.freezed.dart`.

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
