import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  group('applyFieldRename', () {
    test('converts camelCase names like json_serializable', () {
      expect(applyFieldRename('userId', 'snake'), 'user_id');
      expect(applyFieldRename('userId', 'kebab'), 'user-id');
      expect(applyFieldRename('userId', 'pascal'), 'UserId');
      expect(applyFieldRename('userId', 'screamingSnake'), 'USER_ID');
    });

    test('leaves names alone without a strategy', () {
      expect(applyFieldRename('userId', null), 'userId');
      expect(applyFieldRename('userId', 'unknown'), 'userId');
      expect(applyFieldRename('', 'pascal'), '');
    });
  });

  group('generated schemas', () {
    late Map<String, Object?> schemas;
    late Map<String, Object?> paths;

    setUpAll(() async {
      final result = await OpenApiGenerator(
        config: AxleConfig(
          title: 'JSON API',
          version: '1.0.0',
          scan: const ['test/fixtures/json_serializable'],
        ),
        projectRoot: Directory.current,
      ).generate();
      final json = result.document.toJson();
      schemas =
          (json['components']! as Map<String, Object?>)['schemas']!
              as Map<String, Object?>;
      paths = json['paths']! as Map<String, Object?>;
    });

    Map<String, Object?> properties(String schema) =>
        (schemas[schema]! as Map)['properties']! as Map<String, Object?>;

    test('applies snake_case from @JsonSerializable', () {
      expect(
        properties('SnakeProfile').keys,
        containsAll(['user_id', 'display_name', 'status', 'tier']),
      );
      expect(
        (schemas['SnakeProfile']! as Map)['required'],
        containsAll(['user_id', 'display_name']),
      );
    });

    test('lets @JsonKey and @ApiProperty names win over fieldRename', () {
      expect(properties('SnakeProfile').keys, contains('KeepsName'));
      expect(properties('SnakeProfile').keys, contains('api-override'));
      expect(properties('SnakeProfile').keys, isNot(contains('keeps_name')));
    });

    test('supports kebab, pascal, and screamingSnake', () {
      expect(properties('KebabProfile').keys, ['user-id']);
      expect(properties('PascalProfile').keys, ['UserId']);
      expect(properties('ScreamingProfile').keys, ['USER_ID']);
      expect(properties('PlainProfile').keys, ['userId']);
    });

    test('uses the renaming of the class being serialized', () {
      expect(properties('DerivedProfile').keys, ['created_at', 'user_id']);
    });

    test('renames enum values from @JsonEnum and @JsonValue', () {
      expect(properties('SnakeProfile')['status'], {
        'type': 'string',
        'enum': ['active_user', 'pending_review'],
      });
      expect(properties('SnakeProfile')['tier'], {
        'type': 'string',
        'enum': ['free-tier', 'paid'],
      });
    });

    test('documents routes whose path comes from a shared constant', () {
      expect(paths.keys, ['/profiles/{profileId}']);
    });
  });
}
