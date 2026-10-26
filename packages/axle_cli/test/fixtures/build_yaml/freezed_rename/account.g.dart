// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  userName: json['user_name'] as String,
  loginCount: (json['login_count'] as num).toInt(),
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'user_name': instance.userName,
  'login_count': instance.loginCount,
};

_Kept _$KeptFromJson(Map<String, dynamic> json) =>
    _Kept(userName: json['userName'] as String);

Map<String, dynamic> _$KeptToJson(_Kept instance) => <String, dynamic>{
  'userName': instance.userName,
};
