// freezed documents this ignore: `@JsonSerializable` is valid on the factory.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({required String userName, required int loginCount}) =
      _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

@freezed
abstract class Kept with _$Kept {
  @JsonSerializable(fieldRename: FieldRename.none)
  const factory Kept({required String userName}) = _Kept;

  factory Kept.fromJson(Map<String, dynamic> json) => _$KeptFromJson(json);
}
