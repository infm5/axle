# Models and serialization packages

> This page describes axle 0.3.0. With the published 0.2.0, axle reads only
> `@JsonKey(name:)`, `@JsonKey(defaultValue:)`, `@JsonKey(includeToJson:,
> includeFromJson:)` and `@ApiProperty`; the rest needs 0.3.0.

axle reads the same annotations as your serialization package, so the spec
follows the wire format. Run `dart run build_runner build` first: axle reads
generated parts (`*.freezed.dart`, `*.g.dart`, `*.mapper.dart`). Excluding them
in `analysis_options.yaml` is fine.

## Pick the package from `pubspec.yaml`

| The project depends on | Read | Notes |
| --- | --- | --- |
| nothing (hand-written `toJson`) | public fields | Set `@ApiProperty(name: ...)` when `toJson` renames a key. |
| `json_serializable` | `@JsonSerializable(fieldRename:)`, `@JsonKey`, `@JsonEnum`, string `@JsonValue`, `JsonConverter` | `axle_cli` resolves next to it. |
| `freezed` | factory parameters, `@Default`, `@Freezed(unionKey:)`, `@FreezedUnionValue` | `axle_cli` does **not** resolve next to freezed 3.x. |
| `dart_mappable` | `@MappableClass(caseStyle:)`, `@MappableField(key:)`, `@MappableEnum`, `@MappableValue` | `axle_cli` resolves next to `dart_mappable_builder`. |

## Property name precedence

`@ApiProperty(name:)`, then `@JsonKey(name:)`, then `@MappableField(key:)`, then
the class rule (`fieldRename` or `caseStyle`), then the Dart name.

## Custom converters

The schema uses, in order: `@ApiProperty(type: ...)`; the JSON type of a
`JsonConverter<Value, Json>` or of `@JsonKey(toJson:)`; the Dart type. When a
converter hides its JSON type (`Object?`, or `@MappableField(hook:)`), axle warns
`Property X.y uses a custom converter`. Fix it with `@ApiProperty(type: ...)`.

## freezed and `axle_cli`

If `dart pub add --dev axle_cli` fails with `version solving failed` next to
freezed, do not downgrade anything. Install the CLI globally:

```sh
dart pub global activate axle_cli
dart run build_runner build
axle gen            # or: dart pub global run axle_cli:axle gen
```

Keep `axle_core` or the adapter package as a normal dependency; it has no
`analyzer` dependency. In CI, use `dart pub global run axle_cli:axle gen --check`.
Re-run `dart pub global activate axle_cli` after upgrading axle.

freezed unions need no extra annotations: a sealed freezed class becomes `oneOf`
with its `unionKey` (default `runtimeType`) as the discriminator.

## Verify against the wire

After `axle gen`, run the server and compare real responses with the spec:
property names, enum values, and which properties are present. A mismatch means
something axle did not read. axle reads `field_rename` and `ignore_unannotated`
(json_serializable) and `caseStyle` and `enumCaseStyle` (dart_mappable_builder)
from the root `build.yaml`, and fails with exit 65 on invalid or conflicting
values. Check for a converter or a hook next.

Runnable examples: `packages/axle_shelf/example` (json_serializable),
`examples/dart_mappable`, and `examples/freezed_unions` in the axle repository.
