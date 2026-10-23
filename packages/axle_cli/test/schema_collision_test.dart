import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  test('schema names are deduplicated across libraries', () async {
    final config = AxleConfig(
      title: 'Collision API',
      version: '1.0.0',
      scan: const ['test/fixtures/schema_collision'],
    );

    final result = await OpenApiGenerator(
      config: config,
      projectRoot: Directory.current,
    ).generate();
    final json = result.document.toJson();
    final schemas =
        (json['components']! as Map<String, Object?>)['schemas']!
            as Map<String, Object?>;

    expect(schemas.keys, ['DuplicateDto', 'DuplicateDto_2']);
    expect(schemas['DuplicateDto'], {
      'type': 'object',
      'properties': {
        'first': {'type': 'string'},
      },
      'required': ['first'],
    });
    expect(schemas['DuplicateDto_2'], {
      'type': 'object',
      'properties': {
        'second': {'type': 'integer'},
      },
      'required': ['second'],
    });
  });
}
