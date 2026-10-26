# dart_mappable example

A Shelf API whose models are [`dart_mappable`](https://pub.dev/packages/dart_mappable)
classes, documented with axle. It shows that the generated spec follows the
mapper's own annotations, so the schema matches the JSON on the wire.

## How axle reads the models

`lib/src/models/account.dart`:

| In the model | In the spec |
| --- | --- |
| `@MappableClass(caseStyle: CaseStyle.snakeCase)` | `displayName` becomes `display_name` |
| `@MappableField(key: 'joined')` on `createdAt` | the property is `joined`, not `created_at` |
| `@MappableEnum(caseStyle: CaseStyle.upperSnakeCase)` | `pendingReview` becomes `PENDING_REVIEW` |
| `@MappableValue('BLOCKED')` on `suspended` | that value is `BLOCKED` |
| `@ApiProperty(minLength: 3, maxLength: 10)` | constraints on `postal_code` |
| `String? nickname` | optional, `type: [string, null]` |
| `const accountPath = '/accounts/<id>'` | one constant for the router and `@ApiRoute` |

## Run

```sh
dart pub get
dart run build_runner build   # writes account.mapper.dart
dart run axle_cli:axle gen    # writes openapi.json, openapi.yaml, the Dart constant, Swagger UI
dart run bin/server.dart
```

Open <http://localhost:8080/docs>, then compare the spec with the real output:

```sh
curl localhost:8080/accounts/1
curl -X POST localhost:8080/accounts -H 'content-type: application/json' \
  -d '{"display_name":"Grace","address":{"street_line":"1 Navy Rd","postal_code":"10001"}}'
```

The response keys (`display_name`, `joined`, `PENDING_REVIEW`) are exactly the
ones in `openapi.json`.

## Notes

- `axle_cli` is a normal dev dependency here: `dart_mappable_builder` and
  `axle_cli` resolve together.
- `pubspec_overrides.yaml` points the example at the local packages while
  developing the repository. Delete it to use the published ones.
- CI runs `dart run melos run check-dart-mappable-example`, which fails when
  the committed spec is stale.

More: [Models and serialization](https://axle.infms.dev/models/dart-mappable).
