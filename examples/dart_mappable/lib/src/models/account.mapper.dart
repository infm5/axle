// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'account.dart';

class AccountStatusMapper extends EnumMapper<AccountStatus> {
  AccountStatusMapper._();

  static AccountStatusMapper? _instance;
  static AccountStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AccountStatusMapper._());
    }
    return _instance!;
  }

  static AccountStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AccountStatus decode(dynamic value) {
    switch (value) {
      case r'PENDING_REVIEW':
        return AccountStatus.pendingReview;
      case r'ACTIVE':
        return AccountStatus.active;
      case 'BLOCKED':
        return AccountStatus.suspended;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(AccountStatus self) {
    switch (self) {
      case AccountStatus.pendingReview:
        return r'PENDING_REVIEW';
      case AccountStatus.active:
        return r'ACTIVE';
      case AccountStatus.suspended:
        return 'BLOCKED';
    }
  }
}

extension AccountStatusMapperExtension on AccountStatus {
  dynamic toValue() {
    AccountStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AccountStatus>(this);
  }
}

class AddressMapper extends ClassMapperBase<Address> {
  AddressMapper._();

  static AddressMapper? _instance;
  static AddressMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AddressMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Address';

  static String _$streetLine(Address v) => v.streetLine;
  static const Field<Address, String> _f$streetLine = Field(
    'streetLine',
    _$streetLine,
    key: r'street_line',
  );
  static String _$postalCode(Address v) => v.postalCode;
  static const Field<Address, String> _f$postalCode = Field(
    'postalCode',
    _$postalCode,
    key: r'postal_code',
  );
  static String? _$region(Address v) => v.region;
  static const Field<Address, String> _f$region = Field(
    'region',
    _$region,
    opt: true,
  );

  @override
  final MappableFields<Address> fields = const {
    #streetLine: _f$streetLine,
    #postalCode: _f$postalCode,
    #region: _f$region,
  };

  static Address _instantiate(DecodingData data) {
    return Address(
      streetLine: data.dec(_f$streetLine),
      postalCode: data.dec(_f$postalCode),
      region: data.dec(_f$region),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Address fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Address>(map);
  }

  static Address fromJson(String json) {
    return ensureInitialized().decodeJson<Address>(json);
  }
}

mixin AddressMappable {
  String toJson() {
    return AddressMapper.ensureInitialized().encodeJson<Address>(
      this as Address,
    );
  }

  Map<String, dynamic> toMap() {
    return AddressMapper.ensureInitialized().encodeMap<Address>(
      this as Address,
    );
  }

  AddressCopyWith<Address, Address, Address> get copyWith =>
      _AddressCopyWithImpl<Address, Address>(
        this as Address,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AddressMapper.ensureInitialized().stringifyValue(this as Address);
  }

  @override
  bool operator ==(Object other) {
    return AddressMapper.ensureInitialized().equalsValue(
      this as Address,
      other,
    );
  }

  @override
  int get hashCode {
    return AddressMapper.ensureInitialized().hashValue(this as Address);
  }
}

extension AddressValueCopy<$R, $Out> on ObjectCopyWith<$R, Address, $Out> {
  AddressCopyWith<$R, Address, $Out> get $asAddress =>
      $base.as((v, t, t2) => _AddressCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AddressCopyWith<$R, $In extends Address, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? streetLine, String? postalCode, String? region});
  AddressCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AddressCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Address, $Out>
    implements AddressCopyWith<$R, Address, $Out> {
  _AddressCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Address> $mapper =
      AddressMapper.ensureInitialized();
  @override
  $R call({String? streetLine, String? postalCode, Object? region = $none}) =>
      $apply(
        FieldCopyWithData({
          if (streetLine != null) #streetLine: streetLine,
          if (postalCode != null) #postalCode: postalCode,
          if (region != $none) #region: region,
        }),
      );
  @override
  Address $make(CopyWithData data) => Address(
    streetLine: data.get(#streetLine, or: $value.streetLine),
    postalCode: data.get(#postalCode, or: $value.postalCode),
    region: data.get(#region, or: $value.region),
  );

  @override
  AddressCopyWith<$R2, Address, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AddressCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class AccountMapper extends ClassMapperBase<Account> {
  AccountMapper._();

  static AccountMapper? _instance;
  static AccountMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AccountMapper._());
      AccountStatusMapper.ensureInitialized();
      AddressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Account';

  static int _$id(Account v) => v.id;
  static const Field<Account, int> _f$id = Field('id', _$id);
  static String _$displayName(Account v) => v.displayName;
  static const Field<Account, String> _f$displayName = Field(
    'displayName',
    _$displayName,
    key: r'display_name',
  );
  static AccountStatus _$status(Account v) => v.status;
  static const Field<Account, AccountStatus> _f$status = Field(
    'status',
    _$status,
  );
  static Address _$address(Account v) => v.address;
  static const Field<Account, Address> _f$address = Field('address', _$address);
  static DateTime _$createdAt(Account v) => v.createdAt;
  static const Field<Account, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'joined',
  );
  static String? _$nickname(Account v) => v.nickname;
  static const Field<Account, String> _f$nickname = Field(
    'nickname',
    _$nickname,
    opt: true,
  );

  @override
  final MappableFields<Account> fields = const {
    #id: _f$id,
    #displayName: _f$displayName,
    #status: _f$status,
    #address: _f$address,
    #createdAt: _f$createdAt,
    #nickname: _f$nickname,
  };

  static Account _instantiate(DecodingData data) {
    return Account(
      id: data.dec(_f$id),
      displayName: data.dec(_f$displayName),
      status: data.dec(_f$status),
      address: data.dec(_f$address),
      createdAt: data.dec(_f$createdAt),
      nickname: data.dec(_f$nickname),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Account fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Account>(map);
  }

  static Account fromJson(String json) {
    return ensureInitialized().decodeJson<Account>(json);
  }
}

mixin AccountMappable {
  String toJson() {
    return AccountMapper.ensureInitialized().encodeJson<Account>(
      this as Account,
    );
  }

  Map<String, dynamic> toMap() {
    return AccountMapper.ensureInitialized().encodeMap<Account>(
      this as Account,
    );
  }

  AccountCopyWith<Account, Account, Account> get copyWith =>
      _AccountCopyWithImpl<Account, Account>(
        this as Account,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AccountMapper.ensureInitialized().stringifyValue(this as Account);
  }

  @override
  bool operator ==(Object other) {
    return AccountMapper.ensureInitialized().equalsValue(
      this as Account,
      other,
    );
  }

  @override
  int get hashCode {
    return AccountMapper.ensureInitialized().hashValue(this as Account);
  }
}

extension AccountValueCopy<$R, $Out> on ObjectCopyWith<$R, Account, $Out> {
  AccountCopyWith<$R, Account, $Out> get $asAccount =>
      $base.as((v, t, t2) => _AccountCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AccountCopyWith<$R, $In extends Account, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  AddressCopyWith<$R, Address, Address> get address;
  $R call({
    int? id,
    String? displayName,
    AccountStatus? status,
    Address? address,
    DateTime? createdAt,
    String? nickname,
  });
  AccountCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AccountCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Account, $Out>
    implements AccountCopyWith<$R, Account, $Out> {
  _AccountCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Account> $mapper =
      AccountMapper.ensureInitialized();
  @override
  AddressCopyWith<$R, Address, Address> get address =>
      $value.address.copyWith.$chain((v) => call(address: v));
  @override
  $R call({
    int? id,
    String? displayName,
    AccountStatus? status,
    Address? address,
    DateTime? createdAt,
    Object? nickname = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (displayName != null) #displayName: displayName,
      if (status != null) #status: status,
      if (address != null) #address: address,
      if (createdAt != null) #createdAt: createdAt,
      if (nickname != $none) #nickname: nickname,
    }),
  );
  @override
  Account $make(CopyWithData data) => Account(
    id: data.get(#id, or: $value.id),
    displayName: data.get(#displayName, or: $value.displayName),
    status: data.get(#status, or: $value.status),
    address: data.get(#address, or: $value.address),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    nickname: data.get(#nickname, or: $value.nickname),
  );

  @override
  AccountCopyWith<$R2, Account, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AccountCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class NewAccountMapper extends ClassMapperBase<NewAccount> {
  NewAccountMapper._();

  static NewAccountMapper? _instance;
  static NewAccountMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NewAccountMapper._());
      AddressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'NewAccount';

  static String _$displayName(NewAccount v) => v.displayName;
  static const Field<NewAccount, String> _f$displayName = Field(
    'displayName',
    _$displayName,
    key: r'display_name',
  );
  static Address _$address(NewAccount v) => v.address;
  static const Field<NewAccount, Address> _f$address = Field(
    'address',
    _$address,
  );
  static String? _$nickname(NewAccount v) => v.nickname;
  static const Field<NewAccount, String> _f$nickname = Field(
    'nickname',
    _$nickname,
    opt: true,
  );

  @override
  final MappableFields<NewAccount> fields = const {
    #displayName: _f$displayName,
    #address: _f$address,
    #nickname: _f$nickname,
  };

  static NewAccount _instantiate(DecodingData data) {
    return NewAccount(
      displayName: data.dec(_f$displayName),
      address: data.dec(_f$address),
      nickname: data.dec(_f$nickname),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static NewAccount fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<NewAccount>(map);
  }

  static NewAccount fromJson(String json) {
    return ensureInitialized().decodeJson<NewAccount>(json);
  }
}

mixin NewAccountMappable {
  String toJson() {
    return NewAccountMapper.ensureInitialized().encodeJson<NewAccount>(
      this as NewAccount,
    );
  }

  Map<String, dynamic> toMap() {
    return NewAccountMapper.ensureInitialized().encodeMap<NewAccount>(
      this as NewAccount,
    );
  }

  NewAccountCopyWith<NewAccount, NewAccount, NewAccount> get copyWith =>
      _NewAccountCopyWithImpl<NewAccount, NewAccount>(
        this as NewAccount,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return NewAccountMapper.ensureInitialized().stringifyValue(
      this as NewAccount,
    );
  }

  @override
  bool operator ==(Object other) {
    return NewAccountMapper.ensureInitialized().equalsValue(
      this as NewAccount,
      other,
    );
  }

  @override
  int get hashCode {
    return NewAccountMapper.ensureInitialized().hashValue(this as NewAccount);
  }
}

extension NewAccountValueCopy<$R, $Out>
    on ObjectCopyWith<$R, NewAccount, $Out> {
  NewAccountCopyWith<$R, NewAccount, $Out> get $asNewAccount =>
      $base.as((v, t, t2) => _NewAccountCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class NewAccountCopyWith<$R, $In extends NewAccount, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  AddressCopyWith<$R, Address, Address> get address;
  $R call({String? displayName, Address? address, String? nickname});
  NewAccountCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _NewAccountCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, NewAccount, $Out>
    implements NewAccountCopyWith<$R, NewAccount, $Out> {
  _NewAccountCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<NewAccount> $mapper =
      NewAccountMapper.ensureInitialized();
  @override
  AddressCopyWith<$R, Address, Address> get address =>
      $value.address.copyWith.$chain((v) => call(address: v));
  @override
  $R call({String? displayName, Address? address, Object? nickname = $none}) =>
      $apply(
        FieldCopyWithData({
          if (displayName != null) #displayName: displayName,
          if (address != null) #address: address,
          if (nickname != $none) #nickname: nickname,
        }),
      );
  @override
  NewAccount $make(CopyWithData data) => NewAccount(
    displayName: data.get(#displayName, or: $value.displayName),
    address: data.get(#address, or: $value.address),
    nickname: data.get(#nickname, or: $value.nickname),
  );

  @override
  NewAccountCopyWith<$R2, NewAccount, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _NewAccountCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ApiErrorMapper extends ClassMapperBase<ApiError> {
  ApiErrorMapper._();

  static ApiErrorMapper? _instance;
  static ApiErrorMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ApiErrorMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ApiError';

  static String _$code(ApiError v) => v.code;
  static const Field<ApiError, String> _f$code = Field('code', _$code);
  static String _$message(ApiError v) => v.message;
  static const Field<ApiError, String> _f$message = Field('message', _$message);

  @override
  final MappableFields<ApiError> fields = const {
    #code: _f$code,
    #message: _f$message,
  };

  static ApiError _instantiate(DecodingData data) {
    return ApiError(code: data.dec(_f$code), message: data.dec(_f$message));
  }

  @override
  final Function instantiate = _instantiate;

  static ApiError fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ApiError>(map);
  }

  static ApiError fromJson(String json) {
    return ensureInitialized().decodeJson<ApiError>(json);
  }
}

mixin ApiErrorMappable {
  String toJson() {
    return ApiErrorMapper.ensureInitialized().encodeJson<ApiError>(
      this as ApiError,
    );
  }

  Map<String, dynamic> toMap() {
    return ApiErrorMapper.ensureInitialized().encodeMap<ApiError>(
      this as ApiError,
    );
  }

  ApiErrorCopyWith<ApiError, ApiError, ApiError> get copyWith =>
      _ApiErrorCopyWithImpl<ApiError, ApiError>(
        this as ApiError,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ApiErrorMapper.ensureInitialized().stringifyValue(this as ApiError);
  }

  @override
  bool operator ==(Object other) {
    return ApiErrorMapper.ensureInitialized().equalsValue(
      this as ApiError,
      other,
    );
  }

  @override
  int get hashCode {
    return ApiErrorMapper.ensureInitialized().hashValue(this as ApiError);
  }
}

extension ApiErrorValueCopy<$R, $Out> on ObjectCopyWith<$R, ApiError, $Out> {
  ApiErrorCopyWith<$R, ApiError, $Out> get $asApiError =>
      $base.as((v, t, t2) => _ApiErrorCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ApiErrorCopyWith<$R, $In extends ApiError, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? code, String? message});
  ApiErrorCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ApiErrorCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ApiError, $Out>
    implements ApiErrorCopyWith<$R, ApiError, $Out> {
  _ApiErrorCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ApiError> $mapper =
      ApiErrorMapper.ensureInitialized();
  @override
  $R call({String? code, String? message}) => $apply(
    FieldCopyWithData({
      if (code != null) #code: code,
      if (message != null) #message: message,
    }),
  );
  @override
  ApiError $make(CopyWithData data) => ApiError(
    code: data.get(#code, or: $value.code),
    message: data.get(#message, or: $value.message),
  );

  @override
  ApiErrorCopyWith<$R2, ApiError, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ApiErrorCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

