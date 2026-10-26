## Unreleased

- Aligned with `axle_core` 0.3.0. The adapter itself is unchanged.
- The `axle_core` re-export now includes the new annotations: `allOf` and
  `anyOf` on `@ApiSchema`, `ApiResponse.unauthorized`, `forbidden`, `conflict`,
  `unprocessableEntity`, `tooManyRequests`, `defaultResponse`, and `range`,
  parameter `style` and `explode`, `ApiExample`, `ApiRoute(bodies:)`, and
  `ApiProperty(type:)`.
- The re-export also includes `checkDocumentedRoutes`, which tests that every
  path in a generated spec reaches a handler. It is framework-neutral and has
  not been run against a Serverpod web server yet.

## 0.2.0

- Initial public release, aligned with axle 0.2.0.
- `WebServer.mountAxleDocs` for serving the OpenAPI document and Swagger UI.
- `AxleDocsRoute` and `AxleOpenApiRoute` for manual route registration.
- Local Swagger UI assets served by `StaticRoute.directory`.
- Re-exports `axle_core` for one-import Serverpod apps.
