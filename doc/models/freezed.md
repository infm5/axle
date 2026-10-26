# freezed

freezed keeps a data class's fields on a generated mixin as getters, so axle
reads the parameters of the factory constructor instead. Sealed unions become
`oneOf`.

## Setup

`axle_cli` does not resolve in the same `pubspec.yaml` as freezed 3.x, so
install it globally. See
[Installing axle next to your code generator](/models/#installing-axle-next-to-your-code-generator).

```yaml
dependencies:
  axle_shelf: ^0.3.0
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^3.0.0
  json_serializable: ^6.9.0
```

```sh
dart pub global activate axle_cli
dart run build_runner build
axle gen
```

## Data classes

```dart
@freezed
abstract class Order with _$Order {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Order({
    required int id,
    required PaymentMethod method,
    @Default(<String>[]) List<String> itemSkus,
    @Default('open') String status,
    @JsonKey(name: 'note') String? customerNote,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
```

generates:

```json
"Order": {
  "type": "object",
  "properties": {
    "id": { "type": "integer" },
    "item_skus": { "type": "array", "items": { "type": "string" }, "default": [] },
    "method": { "$ref": "#/components/schemas/PaymentMethod" },
    "note": { "type": ["string", "null"] },
    "status": { "type": "string", "default": "open" }
  },
  "required": ["id", "method"]
}
```

| Annotation | Effect |
| --- | --- |
| `@Default(value)` | Adds `default` and makes the parameter optional. |
| `@JsonKey(name: ...)` on a parameter | Sets the property name. |
| `@JsonSerializable(fieldRename: ...)` on the class or the factory | Renames properties. |
| `@ApiProperty(...)` on a parameter | Description, constraints, and the rest of [`@ApiProperty`](/reference/annotations). |

## Unions

A sealed freezed class becomes a `oneOf` of its variants. The union key
(`unionKey`, default `runtimeType`) is the discriminator:

```dart
@Freezed(unionKey: 'type')
sealed class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod.card({
    required String last4,
    required int expMonth,
    required int expYear,
  }) = CardPayment;

  @FreezedUnionValue('bank')
  const factory PaymentMethod.bankTransfer({required String iban}) =
      BankTransferPayment;

  const factory PaymentMethod.wallet({
    required String provider,
    @Default(false) bool verified,
  }) = WalletPayment;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}
```

generates:

```json
"PaymentMethod": {
  "oneOf": [
    { "$ref": "#/components/schemas/BankTransferPayment" },
    { "$ref": "#/components/schemas/CardPayment" },
    { "$ref": "#/components/schemas/WalletPayment" }
  ],
  "discriminator": {
    "propertyName": "type",
    "mapping": {
      "bank": "#/components/schemas/BankTransferPayment",
      "card": "#/components/schemas/CardPayment",
      "wallet": "#/components/schemas/WalletPayment"
    }
  }
}
```

Each variant is built from its factory, with the union key pinned to its value:

```json
"WalletPayment": {
  "type": "object",
  "properties": {
    "provider": { "type": "string" },
    "type": { "type": "string", "enum": ["wallet"] },
    "verified": { "type": "boolean", "default": false }
  },
  "required": ["provider", "type"]
}
```

The variant name is the constructor name, or `@FreezedUnionValue`. freezed's
`unionValueCase` is not read; set `@FreezedUnionValue` on each variant instead.

## Tips

- freezed documents that `@JsonSerializable` on a factory needs
  `// ignore_for_file: invalid_annotation_target`.
- Excluding `*.freezed.dart` and `*.g.dart` in `analysis_options.yaml` is fine.
- Run `build_runner` before `axle gen`.

See [`examples/freezed_unions`](https://github.com/infm5/axle/tree/master/examples/freezed_unions).
