// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PaymentMethod _$PaymentMethodFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'card':
          return CardPayment.fromJson(
            json
          );
                case 'bank':
          return BankTransferPayment.fromJson(
            json
          );
                case 'wallet':
          return WalletPayment.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'PaymentMethod',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$PaymentMethod {



  /// Serializes this PaymentMethod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethod);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentMethod()';
}


}

/// @nodoc
class $PaymentMethodCopyWith<$Res>  {
$PaymentMethodCopyWith(PaymentMethod _, $Res Function(PaymentMethod) __);
}


/// Adds pattern-matching-related methods to [PaymentMethod].
extension PaymentMethodPatterns on PaymentMethod {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CardPayment value)?  card,TResult Function( BankTransferPayment value)?  bankTransfer,TResult Function( WalletPayment value)?  wallet,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CardPayment() when card != null:
return card(_that);case BankTransferPayment() when bankTransfer != null:
return bankTransfer(_that);case WalletPayment() when wallet != null:
return wallet(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CardPayment value)  card,required TResult Function( BankTransferPayment value)  bankTransfer,required TResult Function( WalletPayment value)  wallet,}){
final _that = this;
switch (_that) {
case CardPayment():
return card(_that);case BankTransferPayment():
return bankTransfer(_that);case WalletPayment():
return wallet(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CardPayment value)?  card,TResult? Function( BankTransferPayment value)?  bankTransfer,TResult? Function( WalletPayment value)?  wallet,}){
final _that = this;
switch (_that) {
case CardPayment() when card != null:
return card(_that);case BankTransferPayment() when bankTransfer != null:
return bankTransfer(_that);case WalletPayment() when wallet != null:
return wallet(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String last4,  int expMonth,  int expYear)?  card,TResult Function( String iban)?  bankTransfer,TResult Function( String provider,  bool verified)?  wallet,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CardPayment() when card != null:
return card(_that.last4,_that.expMonth,_that.expYear);case BankTransferPayment() when bankTransfer != null:
return bankTransfer(_that.iban);case WalletPayment() when wallet != null:
return wallet(_that.provider,_that.verified);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String last4,  int expMonth,  int expYear)  card,required TResult Function( String iban)  bankTransfer,required TResult Function( String provider,  bool verified)  wallet,}) {final _that = this;
switch (_that) {
case CardPayment():
return card(_that.last4,_that.expMonth,_that.expYear);case BankTransferPayment():
return bankTransfer(_that.iban);case WalletPayment():
return wallet(_that.provider,_that.verified);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String last4,  int expMonth,  int expYear)?  card,TResult? Function( String iban)?  bankTransfer,TResult? Function( String provider,  bool verified)?  wallet,}) {final _that = this;
switch (_that) {
case CardPayment() when card != null:
return card(_that.last4,_that.expMonth,_that.expYear);case BankTransferPayment() when bankTransfer != null:
return bankTransfer(_that.iban);case WalletPayment() when wallet != null:
return wallet(_that.provider,_that.verified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CardPayment implements PaymentMethod {
  const CardPayment({required this.last4, required this.expMonth, required this.expYear, final  String? $type}): $type = $type ?? 'card';
  factory CardPayment.fromJson(Map<String, dynamic> json) => _$CardPaymentFromJson(json);

 final  String last4;
 final  int expMonth;
 final  int expYear;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardPaymentCopyWith<CardPayment> get copyWith => _$CardPaymentCopyWithImpl<CardPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardPayment&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.expMonth, expMonth) || other.expMonth == expMonth)&&(identical(other.expYear, expYear) || other.expYear == expYear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,last4,expMonth,expYear);

@override
String toString() {
  return 'PaymentMethod.card(last4: $last4, expMonth: $expMonth, expYear: $expYear)';
}


}

/// @nodoc
abstract mixin class $CardPaymentCopyWith<$Res> implements $PaymentMethodCopyWith<$Res> {
  factory $CardPaymentCopyWith(CardPayment value, $Res Function(CardPayment) _then) = _$CardPaymentCopyWithImpl;
@useResult
$Res call({
 String last4, int expMonth, int expYear
});




}
/// @nodoc
class _$CardPaymentCopyWithImpl<$Res>
    implements $CardPaymentCopyWith<$Res> {
  _$CardPaymentCopyWithImpl(this._self, this._then);

  final CardPayment _self;
  final $Res Function(CardPayment) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? last4 = null,Object? expMonth = null,Object? expYear = null,}) {
  return _then(CardPayment(
last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,expMonth: null == expMonth ? _self.expMonth : expMonth // ignore: cast_nullable_to_non_nullable
as int,expYear: null == expYear ? _self.expYear : expYear // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BankTransferPayment implements PaymentMethod {
  const BankTransferPayment({required this.iban, final  String? $type}): $type = $type ?? 'bank';
  factory BankTransferPayment.fromJson(Map<String, dynamic> json) => _$BankTransferPaymentFromJson(json);

 final  String iban;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankTransferPaymentCopyWith<BankTransferPayment> get copyWith => _$BankTransferPaymentCopyWithImpl<BankTransferPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BankTransferPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankTransferPayment&&(identical(other.iban, iban) || other.iban == iban));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,iban);

@override
String toString() {
  return 'PaymentMethod.bankTransfer(iban: $iban)';
}


}

/// @nodoc
abstract mixin class $BankTransferPaymentCopyWith<$Res> implements $PaymentMethodCopyWith<$Res> {
  factory $BankTransferPaymentCopyWith(BankTransferPayment value, $Res Function(BankTransferPayment) _then) = _$BankTransferPaymentCopyWithImpl;
@useResult
$Res call({
 String iban
});




}
/// @nodoc
class _$BankTransferPaymentCopyWithImpl<$Res>
    implements $BankTransferPaymentCopyWith<$Res> {
  _$BankTransferPaymentCopyWithImpl(this._self, this._then);

  final BankTransferPayment _self;
  final $Res Function(BankTransferPayment) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? iban = null,}) {
  return _then(BankTransferPayment(
iban: null == iban ? _self.iban : iban // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class WalletPayment implements PaymentMethod {
  const WalletPayment({required this.provider, this.verified = false, final  String? $type}): $type = $type ?? 'wallet';
  factory WalletPayment.fromJson(Map<String, dynamic> json) => _$WalletPaymentFromJson(json);

 final  String provider;
@JsonKey() final  bool verified;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletPaymentCopyWith<WalletPayment> get copyWith => _$WalletPaymentCopyWithImpl<WalletPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletPayment&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.verified, verified) || other.verified == verified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,verified);

@override
String toString() {
  return 'PaymentMethod.wallet(provider: $provider, verified: $verified)';
}


}

/// @nodoc
abstract mixin class $WalletPaymentCopyWith<$Res> implements $PaymentMethodCopyWith<$Res> {
  factory $WalletPaymentCopyWith(WalletPayment value, $Res Function(WalletPayment) _then) = _$WalletPaymentCopyWithImpl;
@useResult
$Res call({
 String provider, bool verified
});




}
/// @nodoc
class _$WalletPaymentCopyWithImpl<$Res>
    implements $WalletPaymentCopyWith<$Res> {
  _$WalletPaymentCopyWithImpl(this._self, this._then);

  final WalletPayment _self;
  final $Res Function(WalletPayment) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? verified = null,}) {
  return _then(WalletPayment(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Order {

/// The order id.
 int get id;/// How the order is paid.
 PaymentMethod get method;/// The ordered product SKUs.
 List<String> get itemSkus;/// The order state.
 String get status;/// A note from the customer. `@JsonKey(name:)` beats `fieldRename`.
@JsonKey(name: 'note') String? get customerNote;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.itemSkus, itemSkus)&&(identical(other.status, status) || other.status == status)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,method,const DeepCollectionEquality().hash(itemSkus),status,customerNote);

@override
String toString() {
  return 'Order(id: $id, method: $method, itemSkus: $itemSkus, status: $status, customerNote: $customerNote)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 int id, PaymentMethod method, List<String> itemSkus, String status,@JsonKey(name: 'note') String? customerNote
});


$PaymentMethodCopyWith<$Res> get method;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? method = null,Object? itemSkus = null,Object? status = null,Object? customerNote = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,itemSkus: null == itemSkus ? _self.itemSkus : itemSkus // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodCopyWith<$Res> get method {
  
  return $PaymentMethodCopyWith<$Res>(_self.method, (value) {
    return _then(_self.copyWith(method: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  PaymentMethod method,  List<String> itemSkus,  String status, @JsonKey(name: 'note')  String? customerNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.method,_that.itemSkus,_that.status,_that.customerNote);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  PaymentMethod method,  List<String> itemSkus,  String status, @JsonKey(name: 'note')  String? customerNote)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.method,_that.itemSkus,_that.status,_that.customerNote);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  PaymentMethod method,  List<String> itemSkus,  String status, @JsonKey(name: 'note')  String? customerNote)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.method,_that.itemSkus,_that.status,_that.customerNote);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Order implements Order {
  const _Order({required this.id, required this.method, final  List<String> itemSkus = const <String>[], this.status = 'open', @JsonKey(name: 'note') this.customerNote}): _itemSkus = itemSkus;
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

/// The order id.
@override final  int id;
/// How the order is paid.
@override final  PaymentMethod method;
/// The ordered product SKUs.
 final  List<String> _itemSkus;
/// The ordered product SKUs.
@override@JsonKey() List<String> get itemSkus {
  if (_itemSkus is EqualUnmodifiableListView) return _itemSkus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemSkus);
}

/// The order state.
@override@JsonKey() final  String status;
/// A note from the customer. `@JsonKey(name:)` beats `fieldRename`.
@override@JsonKey(name: 'note') final  String? customerNote;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other._itemSkus, _itemSkus)&&(identical(other.status, status) || other.status == status)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,method,const DeepCollectionEquality().hash(_itemSkus),status,customerNote);

@override
String toString() {
  return 'Order(id: $id, method: $method, itemSkus: $itemSkus, status: $status, customerNote: $customerNote)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 int id, PaymentMethod method, List<String> itemSkus, String status,@JsonKey(name: 'note') String? customerNote
});


@override $PaymentMethodCopyWith<$Res> get method;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? method = null,Object? itemSkus = null,Object? status = null,Object? customerNote = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,itemSkus: null == itemSkus ? _self._itemSkus : itemSkus // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodCopyWith<$Res> get method {
  
  return $PaymentMethodCopyWith<$Res>(_self.method, (value) {
    return _then(_self.copyWith(method: value));
  });
}
}


/// @nodoc
mixin _$NewOrder {

 PaymentMethod get method;@ApiProperty(minLength: 1) List<String> get itemSkus;@JsonKey(name: 'note') String? get customerNote;
/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderCopyWith<NewOrder> get copyWith => _$NewOrderCopyWithImpl<NewOrder>(this as NewOrder, _$identity);

  /// Serializes this NewOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrder&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.itemSkus, itemSkus)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,const DeepCollectionEquality().hash(itemSkus),customerNote);

@override
String toString() {
  return 'NewOrder(method: $method, itemSkus: $itemSkus, customerNote: $customerNote)';
}


}

/// @nodoc
abstract mixin class $NewOrderCopyWith<$Res>  {
  factory $NewOrderCopyWith(NewOrder value, $Res Function(NewOrder) _then) = _$NewOrderCopyWithImpl;
@useResult
$Res call({
 PaymentMethod method,@ApiProperty(minLength: 1) List<String> itemSkus,@JsonKey(name: 'note') String? customerNote
});


$PaymentMethodCopyWith<$Res> get method;

}
/// @nodoc
class _$NewOrderCopyWithImpl<$Res>
    implements $NewOrderCopyWith<$Res> {
  _$NewOrderCopyWithImpl(this._self, this._then);

  final NewOrder _self;
  final $Res Function(NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? itemSkus = null,Object? customerNote = freezed,}) {
  return _then(_self.copyWith(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,itemSkus: null == itemSkus ? _self.itemSkus : itemSkus // ignore: cast_nullable_to_non_nullable
as List<String>,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodCopyWith<$Res> get method {
  
  return $PaymentMethodCopyWith<$Res>(_self.method, (value) {
    return _then(_self.copyWith(method: value));
  });
}
}


/// Adds pattern-matching-related methods to [NewOrder].
extension NewOrderPatterns on NewOrder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrder value)  $default,){
final _that = this;
switch (_that) {
case _NewOrder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrder value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PaymentMethod method, @ApiProperty(minLength: 1)  List<String> itemSkus, @JsonKey(name: 'note')  String? customerNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.method,_that.itemSkus,_that.customerNote);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PaymentMethod method, @ApiProperty(minLength: 1)  List<String> itemSkus, @JsonKey(name: 'note')  String? customerNote)  $default,) {final _that = this;
switch (_that) {
case _NewOrder():
return $default(_that.method,_that.itemSkus,_that.customerNote);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PaymentMethod method, @ApiProperty(minLength: 1)  List<String> itemSkus, @JsonKey(name: 'note')  String? customerNote)?  $default,) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.method,_that.itemSkus,_that.customerNote);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _NewOrder implements NewOrder {
  const _NewOrder({required this.method, @ApiProperty(minLength: 1) required final  List<String> itemSkus, @JsonKey(name: 'note') this.customerNote}): _itemSkus = itemSkus;
  factory _NewOrder.fromJson(Map<String, dynamic> json) => _$NewOrderFromJson(json);

@override final  PaymentMethod method;
 final  List<String> _itemSkus;
@override@ApiProperty(minLength: 1) List<String> get itemSkus {
  if (_itemSkus is EqualUnmodifiableListView) return _itemSkus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemSkus);
}

@override@JsonKey(name: 'note') final  String? customerNote;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderCopyWith<_NewOrder> get copyWith => __$NewOrderCopyWithImpl<_NewOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrder&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other._itemSkus, _itemSkus)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,const DeepCollectionEquality().hash(_itemSkus),customerNote);

@override
String toString() {
  return 'NewOrder(method: $method, itemSkus: $itemSkus, customerNote: $customerNote)';
}


}

/// @nodoc
abstract mixin class _$NewOrderCopyWith<$Res> implements $NewOrderCopyWith<$Res> {
  factory _$NewOrderCopyWith(_NewOrder value, $Res Function(_NewOrder) _then) = __$NewOrderCopyWithImpl;
@override @useResult
$Res call({
 PaymentMethod method,@ApiProperty(minLength: 1) List<String> itemSkus,@JsonKey(name: 'note') String? customerNote
});


@override $PaymentMethodCopyWith<$Res> get method;

}
/// @nodoc
class __$NewOrderCopyWithImpl<$Res>
    implements _$NewOrderCopyWith<$Res> {
  __$NewOrderCopyWithImpl(this._self, this._then);

  final _NewOrder _self;
  final $Res Function(_NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? itemSkus = null,Object? customerNote = freezed,}) {
  return _then(_NewOrder(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,itemSkus: null == itemSkus ? _self._itemSkus : itemSkus // ignore: cast_nullable_to_non_nullable
as List<String>,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodCopyWith<$Res> get method {
  
  return $PaymentMethodCopyWith<$Res>(_self.method, (value) {
    return _then(_self.copyWith(method: value));
  });
}
}


/// @nodoc
mixin _$ApiError {

 String get code; String get message;
/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiErrorCopyWith<ApiError> get copyWith => _$ApiErrorCopyWithImpl<ApiError>(this as ApiError, _$identity);

  /// Serializes this ApiError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'ApiError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiErrorCopyWith<$Res>  {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) _then) = _$ApiErrorCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$ApiErrorCopyWithImpl<$Res>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._self, this._then);

  final ApiError _self;
  final $Res Function(ApiError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiError].
extension ApiErrorPatterns on ApiError {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiError value)  $default,){
final _that = this;
switch (_that) {
case _ApiError():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiError value)?  $default,){
final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that.code,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _ApiError():
return $default(_that.code,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _ApiError() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiError implements ApiError {
  const _ApiError({required this.code, required this.message});
  factory _ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);

@override final  String code;
@override final  String message;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiErrorCopyWith<_ApiError> get copyWith => __$ApiErrorCopyWithImpl<_ApiError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'ApiError(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ApiErrorCopyWith<$Res> implements $ApiErrorCopyWith<$Res> {
  factory _$ApiErrorCopyWith(_ApiError value, $Res Function(_ApiError) _then) = __$ApiErrorCopyWithImpl;
@override @useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class __$ApiErrorCopyWithImpl<$Res>
    implements _$ApiErrorCopyWith<$Res> {
  __$ApiErrorCopyWithImpl(this._self, this._then);

  final _ApiError _self;
  final $Res Function(_ApiError) _then;

/// Create a copy of ApiError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_ApiError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
