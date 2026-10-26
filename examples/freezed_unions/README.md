# freezed example

A Shelf API whose models are [`freezed`](https://pub.dev/packages/freezed) data
classes and a union, documented with axle.

## How axle reads the models

`lib/src/models/order.dart`:

| In the model | In the spec |
| --- | --- |
| `@freezed` data class `Order` | properties come from the factory parameters |
| `@JsonSerializable(fieldRename: FieldRename.snake)` on the factory | `itemSkus` becomes `item_skus` |
| `@Default(<String>[])` / `@Default('open')` | `default` is set and the property is optional |
| `@JsonKey(name: 'note')` on `customerNote` | the property is `note` |
| `@Freezed(unionKey: 'type') sealed class PaymentMethod` | `oneOf` of the variants, discriminator `type` |
| `@FreezedUnionValue('bank')` | the `bankTransfer` variant is `bank` |
| `@Default(false) bool verified` on a variant | optional, `default: false` |
| each variant | the union key is pinned: `type: {enum: [wallet]}` |

## Run

axle's CLI does not resolve in the same `pubspec.yaml` as freezed 3.x (they need
different `analyzer` versions), so install the CLI once, globally:

```sh
dart pub global activate axle_cli
dart pub get
dart run build_runner build   # writes order.freezed.dart and order.g.dart
axle gen                      # or: dart pub global run axle_cli:axle gen
dart run bin/server.dart
```

Open <http://localhost:8080/docs>, then compare the spec with the real output:

```sh
curl localhost:8080/orders/1
curl -X POST localhost:8080/orders -H 'content-type: application/json' \
  -d '{"method":{"type":"wallet","provider":"applepay"},"item_skus":["a"]}'
```

Request bodies are decoded with the same union key the spec documents; an
unknown `type` returns `422`.

## Notes

- `axle_core` and `axle_shelf` are normal dependencies. They do not depend on
  `analyzer`, so only the CLI needs to be global.
- Re-run `dart pub global activate axle_cli` after upgrading axle.
- `pubspec_overrides.yaml` points the example at the local packages while
  developing the repository. Delete it to use the published ones.
- CI runs `dart run melos run check-freezed-example`, which fails when the
  committed spec is stale.

More: [Models and serialization](https://axle.infms.dev/models/freezed).
