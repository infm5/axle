# Documentation Quality Checklist

Use this after generation, before declaring the docs complete.

## Contract identity

- [ ] `info.title`, `info.version`, and `info.description` are correct.
- [ ] `info.version` is the API version, not the axle package version.
- [ ] Contact, license, terms, or external docs are present when the project has
      real values for them.
- [ ] `servers` is set only when deployment URLs are known and stable.
- [ ] Global tag descriptions match the tags used by operations.

## Operations

- [ ] Every public handler has an `@ApiRoute` annotation.
- [ ] No internal, debug, or wildcard route is accidentally documented.
- [ ] Each operation has a concise `summary` and a useful `description` where
      behavior is not obvious.
- [ ] Tags are consistent and globally described.
- [ ] Operation ids are unique when a handler has multiple annotations.
- [ ] Deprecated endpoints use `deprecated: true`.
- [ ] Paths in annotations match the framework routes.
- [ ] Public operations explicitly set `security: []` when a global default is
      configured.

## Parameters and bodies

- [ ] Path/query/header/cookie parameters have useful descriptions.
- [ ] Required parameters are marked correctly.
- [ ] Numeric, length, enum, and pattern constraints match runtime validation.
- [ ] Request bodies declare every media type the server accepts.
- [ ] Multipart uploads use `format: 'binary'` for file fields.
- [ ] Defaults and examples are realistic.
- [ ] No secret or internal-only field appears in a request schema.

## Responses

- [ ] Every operation has at least one success response.
- [ ] Likely `400`, `401`, `403`, `404`, and `409` responses are documented.
- [ ] Error schemas are consistent across operations.
- [ ] Response headers are documented and actually emitted.
- [ ] Multiple response media types are used only when the server produces them.
- [ ] Response examples don't expose real tokens, emails, or personal data.

## Security

- [ ] Schemes are defined once in `axle.yaml`.
- [ ] Protected routes reference defined schemes.
- [ ] `401`/`403` responses are documented.
- [ ] OAuth2 scopes are listed and match the authorization server.
- [ ] Public routes are intentionally public.
- [ ] Application middleware actually enforces the documented behavior.

## Schemas

- [ ] DTO doc comments produce meaningful descriptions.
- [ ] Wire names match the serializer.
- [ ] `oneOf` and discriminator mappings are explicit.
- [ ] Internal fields are ignored.
- [ ] Nullability and required fields match the wire contract.
- [ ] No unsupported type shape is silently guessed at.

## Serving and freshness

- [ ] `dart run axle_cli:axle gen` completes without errors.
- [ ] `dart run axle_cli:axle gen --check` passes.
- [ ] Generated artifacts are committed.
- [ ] `/openapi.json` returns valid JSON.
- [ ] `/docs` renders Swagger UI.
- [ ] The Authorize dialog works for protected APIs.
- [ ] Local docs assets load when `swaggerUiDirectory` is used.
- [ ] The docs port/path matches the adapter configuration.

## Validation

- [ ] `dart analyze` passes.
- [ ] The generated spec passes an OpenAPI 3.1 linter.
- [ ] Example requests against the running server match the documented status
      codes.
- [ ] CI runs `gen --check` and the same analyzer/lint checks.
