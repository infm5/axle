# dart_mappable

axle reads `dart_mappable`'s case styles, field keys, and enum values. The
mapper fields are normal Dart fields, so the rest of the model needs no extra
work.

## Setup

```yaml
dependencies:
  axle_shelf: ^0.3.0
  dart_mappable: ^4.4.0

dev_dependencies:
  axle_cli: ^0.3.0
  build_runner: ^2.4.0
  dart_mappable_builder: ^4.4.0
```

`axle_cli` and `dart_mappable_builder` resolve together. Run `dart run
build_runner build`, then `dart run axle_cli:axle gen`.

## What axle reads

| Annotation | Effect on the schema |
| --- | --- |
| `@MappableClass(caseStyle: ...)` | Renames every property. Any `CaseStyle` works; `snakeCase`, `paramCase`, `pascalCase`, and `upperSnakeCase` are tested. |
| `@MappableField(key: ...)` | Sets one property name. Beats `caseStyle`. |
| `@MappableEnum(caseStyle: ...)` | Renames enum values. |
| `@MappableValue(value)` | Sets one enum value. Strings only. |
| `@MappableField(hook: ...)` | Warns: the hook may change the JSON form. Add `@ApiProperty(type: ...)`. |

Not read: `discriminatorKey` and `discriminatorValue`, `includeSubClasses`,
class-level hooks, and custom mappers. A sealed class still becomes a `oneOf`,
but without a discriminator, so axle warns. Add
`@ApiSchema(discriminator: ApiDiscriminator('type', mapping: {...}))` and a
matching property on the subclasses.

## Example

```dart
@MappableEnum(caseStyle: CaseStyle.upperSnakeCase)
enum AccountStatus {
  pendingReview,
  active,
  @MappableValue('BLOCKED')
  suspended,
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class Account with AccountMappable {
  const Account({
    required this.id,
    required this.displayName,
    required this.status,
    required this.address,
    required this.createdAt,
    this.nickname,
  });

  final int id;
  final String displayName;
  final AccountStatus status;
  final Address address;

  @MappableField(key: 'joined')
  final DateTime createdAt;

  final String? nickname;
}
```

generates:

```json
"Account": {
  "type": "object",
  "properties": {
    "address": { "$ref": "#/components/schemas/Address" },
    "display_name": { "type": "string" },
    "id": { "type": "integer" },
    "joined": { "type": "string", "format": "date-time" },
    "nickname": { "type": ["string", "null"] },
    "status": { "type": "string", "enum": ["PENDING_REVIEW", "ACTIVE", "BLOCKED"] }
  },
  "required": ["address", "display_name", "id", "joined", "status"]
}
```

and `account.toJson()` produces the same keys:

```json
{"id":1,"display_name":"Ada Lovelace","status":"ACTIVE","address":{"street_line":"12 Analytical Way","postal_code":"N1 9GU","region":null},"joined":"2026-01-05T00:00:00.000Z","nickname":null}
```

See [`examples/dart_mappable`](https://github.com/infm5/axle/tree/master/examples/dart_mappable).
