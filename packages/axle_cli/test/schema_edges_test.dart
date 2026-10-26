import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  group('schema edge cases', () {
    late GeneratedSpec result;
    late Map<String, Object?> schemas;

    setUpAll(() async {
      final config = AxleConfig(
        title: 'Schema Edge API',
        version: '1.0.0',
        scan: const ['test/fixtures/schema_edges'],
      );
      result = await OpenApiGenerator(
        config: config,
        projectRoot: Directory.current,
      ).generate();
      final json = result.document.toJson();
      schemas =
          (json['components']! as Map<String, Object?>)['schemas']!
              as Map<String, Object?>;
    });

    test('renames, sanitizes, and ignores annotated schemas', () {
      expect(schemas.keys, [
        'BaseDto',
        'ChildDto',
        'EdgeTypesDto',
        'ExampleValuesDto',
        'NodeDto',
        'RenamedDto',
        '_123_weird_name',
      ]);
      expect(schemas['RenamedDto'], {
        'type': 'object',
        'properties': {
          'value': {'type': 'string'},
        },
        'required': ['value'],
        'description': 'A renamed schema.',
      });
    });

    test('includes inherited fields and recursive references', () {
      final child = schemas['ChildDto']! as Map;
      expect(child['properties'], {
        'base': {'type': 'string'},
        'child': {'type': 'integer'},
      });
      expect(child['required'], ['base', 'child']);

      final node = schemas['NodeDto']! as Map;
      final next = (node['properties'] as Map)['next'];
      expect(next, {
        'anyOf': [
          {r'$ref': '#/components/schemas/NodeDto'},
          {'type': 'null'},
        ],
      });
    });

    test('maps scalar and collection types', () {
      final properties = (schemas['EdgeTypesDto']! as Map)['properties'] as Map;

      expect(properties['uri'], {'type': 'string', 'format': 'uri'});
      expect(properties['duration'], {'type': 'string', 'format': 'duration'});
      expect(properties['big'], {'type': 'integer', 'format': 'int64'});
      expect(properties['bytes'], {'type': 'string', 'format': 'byte'});
      expect(properties['bytesData'], {'type': 'string', 'format': 'byte'});
      expect(properties['anything'], isEmpty);
      expect(properties['object'], isEmpty);
      expect(properties['neverValue'], isEmpty);
      expect(properties['nothing'], {'type': 'null'});
      expect(properties['rawList'], {
        'type': 'array',
        'items': <String, Object?>{},
      });
      expect(properties['rawMap'], {
        'type': 'object',
        'additionalProperties': <String, Object?>{},
      });
      expect(properties['intKeys'], {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      expect(properties['tags'], {
        'type': 'array',
        'items': {'type': 'string'},
      });
      expect(properties['numbers'], {
        'type': 'array',
        'items': {'type': 'integer'},
      });
      expect(properties['future'], {'type': 'string'});
      expect(properties['futureOr'], {'type': 'integer'});
      expect(properties['optional'], {
        'type': ['string', 'null'],
      });
    });

    test('applies property metadata and skips ignored fields', () {
      final schema = schemas['EdgeTypesDto']! as Map;
      final properties = schema['properties'] as Map;

      expect(properties['withExample'], {
        'type': 'string',
        'example': 'example',
      });
      expect(properties['withDefault'], {
        'type': 'string',
        'default': 'fallback',
      });
      expect(properties['forcedRequired'], {
        'type': ['string', 'null'],
      });
      expect(properties, isNot(contains('ignored')));
      expect(properties, isNot(contains('jsonIgnored')));
      expect(properties, isNot(contains('staticField')));
      expect(properties, isNot(contains('_private')));

      final required = schema['required'] as List;
      expect(required, contains('withExample'));
      expect(required, contains('forcedRequired'));
      expect(required, isNot(contains('withDefault')));
      expect(required, isNot(contains('optional')));
    });

    test('serializes scalar, list, set, map, and enum examples', () {
      final properties =
          (schemas['ExampleValuesDto']! as Map)['properties'] as Map;

      expect(properties['doubleValue'], {'type': 'number', 'example': 1.5});
      expect(properties['listValue'], {
        'type': 'array',
        'items': {'type': 'integer'},
        'example': [1, 2],
      });
      expect(properties['setValue'], {
        'type': 'array',
        'items': {'type': 'integer'},
        'example': [1, 2],
      });
      expect(properties['mapValue'], {
        'type': 'object',
        'additionalProperties': {'type': 'integer'},
        'example': {'a': 1},
      });
      expect(properties['enumValue'], {
        'type': 'string',
        'enum': ['one', 'two'],
        'example': 'two',
      });
    });

    test('warns about non-string map keys', () {
      expect(
        result.warnings,
        contains(
          'Map keys in EdgeTypesDto.intKeys are not Strings; JSON object '
          'keys must be strings. The generated schema still uses an object.',
        ),
      );
    });
  });

  group('schema errors', () {
    const cases = ['duplicate_property', 'function_type', 'record_type'];

    for (final testCase in cases) {
      test('rejects $testCase', () async {
        final config = AxleConfig(
          title: 'Invalid Schema API',
          version: '1.0.0',
          scan: ['test/fixtures/errors/$testCase'],
        );

        await expectLater(
          OpenApiGenerator(
            config: config,
            projectRoot: Directory.current,
          ).generate(),
          throwsA(
            isA<AxleException>().having(
              (error) => error.exitCode,
              'exitCode',
              AxleExitCode.data,
            ),
          ),
        );
      });
    }
  });
}
