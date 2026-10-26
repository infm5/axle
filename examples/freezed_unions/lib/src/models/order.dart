/// Models for the orders API.
///
/// They are ordinary freezed classes. axle reads the factory parameters of a
/// data class, and turns a sealed union into `oneOf` with the union key.
// freezed documents this ignore: `@JsonSerializable` is valid on the factory.
// ignore_for_file: invalid_annotation_target

library;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// How an order is paid.
///
/// `unionKey` is the JSON property that names the variant, so axle emits it as
/// the discriminator. `@FreezedUnionValue` renames one variant's value.
@Freezed(unionKey: 'type')
sealed class PaymentMethod with _$PaymentMethod {
  /// A card payment (`type: card`).
  const factory PaymentMethod.card({
    required String last4,
    required int expMonth,
    required int expYear,
  }) = CardPayment;

  /// A bank transfer (`type: bank`).
  @FreezedUnionValue('bank')
  const factory PaymentMethod.bankTransfer({required String iban}) =
      BankTransferPayment;

  /// A wallet payment (`type: wallet`).
  const factory PaymentMethod.wallet({
    required String provider,
    @Default(false) bool verified,
  }) = WalletPayment;

  /// Reads a payment method from JSON.
  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

/// An order returned by the API.
@freezed
abstract class Order with _$Order {
  /// Creates an order.
  ///
  /// `fieldRename` on the factory renames every property; `@Default` makes a
  /// parameter optional and records its default in the schema.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Order({
    /// The order id.
    required int id,

    /// How the order is paid.
    required PaymentMethod method,

    /// The ordered product SKUs.
    @Default(<String>[]) List<String> itemSkus,

    /// The order state.
    @Default('open') String status,

    /// A note from the customer. `@JsonKey(name:)` beats `fieldRename`.
    @JsonKey(name: 'note') String? customerNote,
  }) = _Order;

  /// Reads an order from JSON.
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// The request body for creating an order.
@freezed
abstract class NewOrder with _$NewOrder {
  /// Creates a request.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NewOrder({
    required PaymentMethod method,
    @ApiProperty(minLength: 1) required List<String> itemSkus,
    @JsonKey(name: 'note') String? customerNote,
  }) = _NewOrder;

  /// Reads a request from JSON.
  factory NewOrder.fromJson(Map<String, dynamic> json) =>
      _$NewOrderFromJson(json);
}

/// An error response.
@freezed
abstract class ApiError with _$ApiError {
  /// Creates an error.
  const factory ApiError({required String code, required String message}) =
      _ApiError;

  /// Reads an error from JSON.
  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
