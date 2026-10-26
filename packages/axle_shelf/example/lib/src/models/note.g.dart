// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': ?instance.description,
  'completed': instance.completed,
  'createdAt': instance.createdAt.toIso8601String(),
};

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': instance.status,
  'checkedAt': instance.checkedAt.toIso8601String(),
};

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
};

Map<String, dynamic> _$NoteStatsToJson(NoteStats instance) => <String, dynamic>{
  'window': instance.window,
  'total': instance.total,
  'completed': instance.completed,
  'active': instance.active,
  'matching': instance.matching,
};

Map<String, dynamic> _$ImportResultToJson(ImportResult instance) =>
    <String, dynamic>{'bytes': instance.bytes};
