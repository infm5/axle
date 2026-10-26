import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

Future<Map<String, Object?>> _schemas(String directory) async {
  final result = await OpenApiGenerator(
    config: AxleConfig(title: 'Models', version: '1.0.0', scan: [directory]),
    projectRoot: Directory.current,
  ).generate();
  final components =
      result.document.toJson()['components']! as Map<String, Object?>;
  return components['schemas']! as Map<String, Object?>;
}

Map<String, Object?> _properties(Map<String, Object?> schemas, String name) =>
    (schemas[name]! as Map)['properties']! as Map<String, Object?>;

void main() {
  group('freezed', () {
    late Map<String, Object?> schemas;
    setUpAll(() async => schemas = await _schemas('test/fixtures/freezed'));

    test('reads a data class from its factory parameters', () {
      final person = schemas['Person']! as Map;
      expect((person['properties']! as Map).keys, [
        'age',
        'e_mail',
        'name',
        'role',
        'tags',
      ]);
    });

    test('marks defaulted and nullable parameters as optional', () {
      final person = schemas['Person']! as Map;
      expect(person['required'], ['name']);
      expect(_properties(schemas, 'Person')['role'], {
        'type': 'string',
        'default': 'guest',
      });
      expect(_properties(schemas, 'Person')['tags'], {
        'type': 'array',
        'items': {'type': 'string'},
        'default': <Object?>[],
      });
    });

    test('honors @JsonKey(name:) on a parameter', () {
      expect(_properties(schemas, 'Person').keys, contains('e_mail'));
      expect(_properties(schemas, 'Person').keys, isNot(contains('email')));
    });

    test('turns a union into oneOf with its union key', () {
      expect(schemas['Shape'], {
        'oneOf': [
          {r'$ref': '#/components/schemas/Circle'},
          {r'$ref': '#/components/schemas/Polygon'},
          {r'$ref': '#/components/schemas/Square'},
        ],
        'discriminator': {
          'propertyName': 'type',
          'mapping': {
            'circle': '#/components/schemas/Circle',
            'polygon': '#/components/schemas/Polygon',
            'sq': '#/components/schemas/Square',
          },
        },
      });
    });

    test('describes each variant, including its discriminator property', () {
      expect(_properties(schemas, 'Circle').keys, ['radius', 'type']);
      expect(_properties(schemas, 'Square').keys, ['side', 'type']);
    });

    test('pins the union key to the variant value', () {
      expect(_properties(schemas, 'Circle')['type'], {
        'type': 'string',
        'enum': ['circle'],
      });
      expect(_properties(schemas, 'Square')['type'], {
        'type': 'string',
        'enum': ['sq'],
      });
      expect((schemas['Circle']! as Map)['required'], ['radius', 'type']);
    });

    test('takes defaults of a union variant from its factory', () {
      final polygon = schemas['Polygon']! as Map;
      expect(polygon['required'], ['sides', 'type']);
      expect(_properties(schemas, 'Polygon')['regular'], {
        'type': 'boolean',
        'default': false,
      });
    });
  });

  group('dart_mappable', () {
    late Map<String, Object?> schemas;
    setUpAll(() async => schemas = await _schemas('test/fixtures/mappable'));

    test('applies the caseStyle of @MappableClass', () {
      expect(_properties(schemas, 'KebabAccount').keys, ['user-name']);
      expect(_properties(schemas, 'PascalAccount').keys, ['UserName']);
      expect(_properties(schemas, 'ConstantAccount').keys, ['USER_NAME']);
      expect(_properties(schemas, 'PlainAccount').keys, ['userName']);
    });

    test('lets @MappableField(key:) win over caseStyle', () {
      expect(_properties(schemas, 'Account').keys, [
        'level',
        'login_count',
        'mail',
        'user_name',
      ]);
    });

    test('applies @MappableEnum and @MappableValue to enum values', () {
      expect(_properties(schemas, 'Account')['level'], {
        'type': 'string',
        'enum': ['LOW_LEVEL', 'HIGH_LEVEL', 'top'],
      });
    });
  });
}
