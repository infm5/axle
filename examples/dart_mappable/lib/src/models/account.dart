/// Models for the accounts API.
///
/// They are plain `dart_mappable` classes. axle reads the same annotations the
/// mapper uses, so the generated schema and the JSON on the wire agree.
library;

import 'package:axle_shelf/axle_shelf.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'account.mapper.dart';

/// Where an account is in its lifecycle.
///
/// `caseStyle` renames the values on the wire (`PENDING_REVIEW`), and
/// `@MappableValue` overrides a single one.
@MappableEnum(caseStyle: CaseStyle.upperSnakeCase)
enum AccountStatus {
  pendingReview,
  active,
  @MappableValue('BLOCKED')
  suspended,
}

/// A postal address.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class Address with AddressMappable {
  /// Creates an address.
  const Address({
    required this.streetLine,
    required this.postalCode,
    this.region,
  });

  /// The street and number.
  final String streetLine;

  /// The postal code.
  @ApiProperty(minLength: 3, maxLength: 10)
  final String postalCode;

  /// The state or region, when it applies.
  final String? region;
}

/// An account returned by the API.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class Account with AccountMappable {
  /// Creates an account.
  const Account({
    required this.id,
    required this.displayName,
    required this.status,
    required this.address,
    required this.createdAt,
    this.nickname,
  });

  /// The account id.
  final int id;

  /// The name shown to other people.
  final String displayName;

  /// The lifecycle state.
  final AccountStatus status;

  /// The billing address.
  final Address address;

  /// When the account was created. `@MappableField(key:)` beats `caseStyle`,
  /// so this is `joined` rather than `created_at`.
  @MappableField(key: 'joined')
  final DateTime createdAt;

  /// An optional short name.
  final String? nickname;
}

/// The request body for creating an account.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class NewAccount with NewAccountMappable {
  /// Creates a request.
  const NewAccount({
    required this.displayName,
    required this.address,
    this.nickname,
  });

  /// The name shown to other people.
  @ApiProperty(minLength: 1, maxLength: 80)
  final String displayName;

  /// The billing address.
  final Address address;

  /// An optional short name.
  final String? nickname;
}

/// An error response.
@MappableClass()
class ApiError with ApiErrorMappable {
  /// Creates an error.
  const ApiError({required this.code, required this.message});

  /// A stable error code.
  final String code;

  /// A human-readable message.
  final String message;
}
