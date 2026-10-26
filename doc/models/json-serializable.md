# json_serializable

axle reads the annotations `json_serializable` reads, so the schema matches the
JSON your generated `toJson` and `fromJson` use.

## Setup

```yaml
dependencies:
  axle_shelf: ^0.3.0
  json_annotation: ^4.9.0

dev_dependencies:
  axle_cli: ^0.3.0
  build_runner: ^2.4.0
  json_serializable: ^6.9.0
```

`axle_cli` and `json_serializable` resolve together. Run `dart run build_runner
build`, then `dart run axle_cli:axle gen`.

## What axle reads

| Annotation | Effect on the schema |
| --- | --- |
| `@JsonSerializable(fieldRename: ...)` | Renames properties: `snake`, `kebab`, `pascal`, `screamingSnake`. Inherited fields use the renaming of the class being serialized. |
| `@JsonKey(name: ...)` | Sets one property name. Beats `fieldRename`. |
| `@JsonKey(defaultValue: ...)` | Adds `default` and makes the property optional. |
| `@JsonKey(includeToJson: false, includeFromJson: false)` | Leaves the property out. |
| `@JsonSerializable(ignoreUnannotated: true)` | Documents only fields that have `@JsonKey`. |
| `@JsonKey(toJson: ..., fromJson: ...)` | Uses the function's JSON type. See [how a type is chosen](/models/#how-a-property-s-type-is-chosen). |
| `@JsonConverter` subclasses | Uses the converter's second type argument. |
| `@JsonEnum(fieldRename: ...)` | Renames enum values. |
| `@JsonValue('x')` | Sets one enum value. Strings only. |

Project-wide `field_rename` and `ignore_unannotated` in `build.yaml` are read
too; see [Options in `build.yaml`](/models/#options-in-build-yaml). A class that
sets `fieldRename` or `ignoreUnannotated` itself keeps its own value.

## Example

```dart
@JsonEnum(fieldRename: FieldRename.snake)
enum AccountStatus { activeUser, pendingReview }

class EpochConverter extends JsonConverter<DateTime, int> {
  const EpochConverter();
  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);
  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

@ApiSchema()
@JsonSerializable(fieldRename: FieldRename.snake)
class Profile {
  Profile({
    required this.userId,
    required this.status,
    required this.joinedAt,
    this.keepsName,
  });

  final int userId;
  final AccountStatus status;

  @EpochConverter()
  final DateTime joinedAt;

  @JsonKey(name: 'KeepsName')
  final String? keepsName;
}
```

generates:

```json
"Profile": {
  "type": "object",
  "properties": {
    "KeepsName": { "type": ["string", "null"] },
    "joined_at": { "type": "integer" },
    "status": { "type": "string", "enum": ["active_user", "pending_review"] },
    "user_id": { "type": "integer" }
  },
  "required": ["joined_at", "status", "user_id"]
}
```

`joined_at` is an integer because the converter produces an `int`, not because
the field is a `DateTime`.

## Response models in the Shelf example

The Shelf example uses generated encoders for its response models and keeps
hand-written validation for requests, so each handler can return a specific
error code:

```dart
@JsonSerializable(createFactory: false, includeIfNull: false)
class Note {
  // ...
  Map<String, Object?> toJson() => _$NoteToJson(this);
}
```

`includeIfNull: false` keeps an unset `description` out of the response, which
matches the schema, where it is an optional property.

See [`packages/axle_shelf/example`](https://github.com/infm5/axle/tree/master/packages/axle_shelf/example).
