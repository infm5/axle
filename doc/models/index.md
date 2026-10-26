# Models and serialization

axle describes the JSON your server sends and receives by reading your Dart
source. It never imports or runs your code, so it reads the same annotations
your serialization package reads, and the schema follows the wire format.

| Package | Page |
| --- | --- |
| Plain classes with hand-written `toJson` | [below](#plain-classes) |
| `json_serializable` | [json_serializable](/models/json-serializable) |
| `freezed` (data classes and unions) | [freezed](/models/freezed) |
| `dart_mappable` | [dart_mappable](/models/dart-mappable) |

::: info New in 0.3.0
Support for these packages is new in axle 0.3.0. Version `0.2.x` reads `@JsonKey(name:)`, `@JsonKey(defaultValue:)`,
`@JsonKey(includeToJson:, includeFromJson:)`, and `@ApiProperty`, and nothing
else on this page. See the [roadmap](/guide/roadmap#_0-3-0).
:::

Each page has a runnable example in the repository. The examples check that
the generated spec matches what the server really sends.

## How a property is named

The first match wins:

1. `@ApiProperty(name:)`
2. `@JsonKey(name:)`
3. `@MappableField(key:)`
4. The class-level rule: `@JsonSerializable(fieldRename:)` or
   `@MappableClass(caseStyle:)`
5. The Dart field name

Enum values follow `@JsonEnum(fieldRename:)` / `@MappableEnum(caseStyle:)`, and
`@JsonValue` / `@MappableValue` for single values.

## Options in `build.yaml`

`json_serializable` and `dart_mappable_builder` accept project-wide options in
`build.yaml`, and some of them change the JSON a server sends. axle reads the
`build.yaml` at the project root, so the spec follows them:

| Builder option | What axle does |
| --- | --- |
| `json_serializable` `field_rename` | Renames properties of every class json_serializable processes, including freezed classes with a `fromJson` factory. A class that sets its own `fieldRename`, even `FieldRename.none`, keeps that. |
| `json_serializable` `ignore_unannotated` | Documents only fields with `@JsonKey`. A class can override it with `ignoreUnannotated:`. |
| `dart_mappable_builder` `caseStyle` | The default case style of `@MappableClass`. A class-level `caseStyle` wins. |
| `dart_mappable_builder` `enumCaseStyle` | The default case style of `@MappableEnum`. dart_mappable does not map an unannotated enum, so those keep their Dart names. |

Options can sit under `targets.<target>.builders.<builder>.options` or under
`global_options`. Every other option (`explicit_to_json`, `include_if_null`,
`create_factory`, and so on) leaves the shape of the JSON unchanged, so axle
ignores it.

axle fails with exit code 65, instead of writing a spec that disagrees with the
server, when:

- an option has a value the builder would reject (`field_rename: shouty`) or
  ignores (`caseStyle: upperSnakeCase`, which `dart_mappable_builder` skips);
- the same option is set to different values in two places, so it is unclear
  which one the builder uses;
- `ignore_unannotated: true` is set and the project has freezed classes with a
  `fromJson` factory, which axle cannot apply it to.

These rules were checked by running the real builders with the same options and
comparing their generated encoders.

## How a property's type is chosen

A custom converter can change the JSON form of a field, for example a
`DateTime` that is sent as an integer. axle picks the type that describes the
JSON in this order:

1. `@ApiProperty(type: ...)`, which always wins.
2. The JSON type of the converter:
   - the second type argument of a `JsonConverter<Value, Json>` annotation on
     the field, or on the class when the field has the converter's value type;
   - the return type of `@JsonKey(toJson: ...)`, or the parameter type of
     `@JsonKey(fromJson: ...)` when only that is set.
3. The Dart type of the field.

If a converter hides its JSON type (`JsonConverter<Money, Object?>`, or a
`@MappableField(hook: ...)`), axle falls back to the Dart type and prints a
warning. Add `@ApiProperty(type: ...)` to say what the JSON really is. The field
still decides nullability.

## Required, optional, and defaults

A property is required when its Dart type is not nullable and it has no default.
A default comes from `@JsonKey(defaultValue:)` or, for freezed, `@Default(...)`,
and is written to the schema as `default`. `@ApiProperty(required:)` overrides
both.

## Plain classes

Without a serialization package, annotate the fields and write `toJson`
yourself. axle reads the public fields:

```dart
@ApiSchema(description: 'A health check response.')
class Health {
  const Health({required this.status, required this.checkedAt});

  final String status;
  final DateTime checkedAt;

  Map<String, Object?> toJson() => {
    'status': status,
    'checkedAt': checkedAt.toIso8601String(),
  };
}
```

When the names in `toJson` differ from the field names, set
`@ApiProperty(name: ...)` on the field so the spec matches.

## Run `build_runner` first

axle reads generated parts (`*.freezed.dart`, `*.g.dart`, `*.mapper.dart`) as
part of their library. Generate them before `axle gen`. Excluding generated files
in `analysis_options.yaml` is fine.

## Installing axle next to your code generator

`axle_cli` needs a recent `analyzer`, and code generators pin their own range.
Whether they fit in one `pubspec.yaml` depends on the generator. As of
2026-10-24, with Dart 3.12:

| Generator | `axle_cli` as a dev dependency |
| --- | --- |
| `json_serializable` 6.15 | Works |
| `dart_mappable_builder` | Works |
| `freezed` 3.x | Does not resolve. freezed 3.x supports `analyzer` up to 12, and `axle_cli` needs 14.5 or newer. freezed 4 needs Dart 3.13. |

When pub cannot solve it, install the CLI once, globally. It then analyzes your
project using your project's own packages:

```sh
dart pub global activate axle_cli
axle gen        # or: dart pub global run axle_cli:axle gen
```

Keep `axle_core` (or an adapter such as `axle_shelf`) as a normal dependency;
it has no `analyzer` dependency. Re-run `dart pub global activate axle_cli` after
upgrading so the installed snapshot is current.

## Examples

| Example | Shows |
| --- | --- |
| [`packages/axle_shelf/example`](https://github.com/infm5/axle/tree/master/packages/axle_shelf/example) | `json_serializable` response models next to hand-validated requests |
| [`examples/dart_mappable`](https://github.com/infm5/axle/tree/master/examples/dart_mappable) | `dart_mappable` with case styles, field keys, and enum values |
| [`examples/freezed_unions`](https://github.com/infm5/axle/tree/master/examples/freezed_unions) | freezed data classes and a union with a union key, using the global CLI |
