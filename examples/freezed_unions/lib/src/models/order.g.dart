// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardPayment _$CardPaymentFromJson(Map<String, dynamic> json) => CardPayment(
  last4: json['last4'] as String,
  expMonth: (json['expMonth'] as num).toInt(),
  expYear: (json['expYear'] as num).toInt(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$CardPaymentToJson(CardPayment instance) =>
    <String, dynamic>{
      'last4': instance.last4,
      'expMonth': instance.expMonth,
      'expYear': instance.expYear,
      'type': instance.$type,
    };

BankTransferPayment _$BankTransferPaymentFromJson(Map<String, dynamic> json) =>
    BankTransferPayment(
      iban: json['iban'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$BankTransferPaymentToJson(
  BankTransferPayment instance,
) => <String, dynamic>{'iban': instance.iban, 'type': instance.$type};

WalletPayment _$WalletPaymentFromJson(Map<String, dynamic> json) =>
    WalletPayment(
      provider: json['provider'] as String,
      verified: json['verified'] as bool? ?? false,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WalletPaymentToJson(WalletPayment instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'verified': instance.verified,
      'type': instance.$type,
    };

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: (json['id'] as num).toInt(),
  method: PaymentMethod.fromJson(json['method'] as Map<String, dynamic>),
  itemSkus:
      (json['item_skus'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  status: json['status'] as String? ?? 'open',
  customerNote: json['note'] as String?,
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'method': instance.method,
  'item_skus': instance.itemSkus,
  'status': instance.status,
  'note': instance.customerNote,
};

_NewOrder _$NewOrderFromJson(Map<String, dynamic> json) => _NewOrder(
  method: PaymentMethod.fromJson(json['method'] as Map<String, dynamic>),
  itemSkus: (json['item_skus'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  customerNote: json['note'] as String?,
);

Map<String, dynamic> _$NewOrderToJson(_NewOrder instance) => <String, dynamic>{
  'method': instance.method,
  'item_skus': instance.itemSkus,
  'note': instance.customerNote,
};

_ApiError _$ApiErrorFromJson(Map<String, dynamic> json) =>
    _ApiError(code: json['code'] as String, message: json['message'] as String);

Map<String, dynamic> _$ApiErrorToJson(_ApiError instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
};
