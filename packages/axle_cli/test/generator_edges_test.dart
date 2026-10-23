import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  group('generator edge cases', () {
    late GeneratedSpec result;
    late Map<String, Object?> paths;

    setUpAll(() async {
      final config = AxleConfig(
        title: 'Edge API',
        version: '1.0.0',
        scan: const ['test/fixtures/edge_cases'],
      );
      result = await OpenApiGenerator(
        config: config,
        projectRoot: Directory.current,
      ).generate();
      paths = result.document.toJson()['paths']! as Map<String, Object?>;
    });

    test('builds header parameters and operation metadata', () {
      final operation = (paths['/headers']! as Map)['get'] as Map;

      expect(operation['operationId'], 'headers');
      expect(operation['summary'], 'Header example');
      expect(operation['description'], 'Exercises header parameters.');
      expect(operation['tags'], ['Edge']);
      expect(operation['deprecated'], isTrue);
      expect(operation['parameters'], [
        {
          'name': 'X-Token',
          'in': 'header',
          'description': 'A token.',
          'required': true,
          'schema': {'type': 'string'},
          'example': 'abc',
        },
      ]);
    });

    test('defaults empty responses to 200 OK', () {
      final operation = (paths['/defaults']! as Map)['get'] as Map;

      expect(operation['responses'], {
        '200': {'description': 'OK'},
      });
    });

    test('uses a fallback description for unknown status codes', () {
      final operation = (paths['/teapot']! as Map)['get'] as Map;

      expect(operation['responses'], {
        '418': {'description': 'Response'},
      });
    });

    test('warns about path placeholders without annotations', () {
      final operation = (paths['/missing/{id}']! as Map)['get'] as Map;

      expect(operation['parameters'], [
        {
          'name': 'id',
          'in': 'path',
          'required': true,
          'schema': {'type': 'string'},
        },
      ]);
      expect(
        result.warnings,
        contains(
          'Path `GET /missing/{id}` has parameter `{id}` without an '
          '@ApiPathParam. A string schema was used.',
        ),
      );
    });

    test('omits ignored routes', () {
      expect(paths, isNot(contains('/ignored')));
    });

    test('writes nullable response schemas', () {
      final operation = (paths['/nullable']! as Map)['get'] as Map;
      final response = (operation['responses'] as Map)['200'] as Map;

      expect(response['description'], 'OK');
      expect(response['content']['application/json']['schema'], {
        'type': ['string', 'null'],
      });
    });
  });

  group('generator errors', () {
    const cases = [
      'duplicate_route',
      'duplicate_operation_id',
      'unused_path_param',
      'invalid_status',
      'duplicate_status',
      'empty_path_param',
      'empty_path',
    ];

    for (final testCase in cases) {
      test('rejects $testCase', () async {
        final config = AxleConfig(
          title: 'Invalid API',
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
