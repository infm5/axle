import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> schemas;

  setUpAll(() async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Composition',
        version: '1.0.0',
        scan: const ['test/fixtures/composition'],
      ),
      projectRoot: Directory.current,
    ).generate();
    final components =
        result.document.toJson()['components']! as Map<String, Object?>;
    schemas = components['schemas']! as Map<String, Object?>;
  });

  Map<String, Object?> ref(String name) => {
    r'$ref': '#/components/schemas/$name',
  };

  test(
    'allOf references the base and adds only the fields the class declares',
    () {
      expect(schemas['Dog'], {
        'description': 'A dog.',
        'allOf': [
          ref('Animal'),
          {
            'type': 'object',
            'properties': {
              'age': {
                'type': ['integer', 'null'],
              },
              'goodBoy': {'type': 'boolean'},
            },
            'required': ['goodBoy'],
          },
        ],
      });
    },
  );

  test('allOf without own fields is just the references', () {
    expect(schemas['PlainAnimal'], {
      'allOf': [ref('Animal')],
    });
  });

  test('anyOf lists the types and accepts a discriminator', () {
    expect(schemas['Contact'], {
      'description': 'Any way to reach someone.',
      'anyOf': [ref('Phone'), ref('Email')],
      'discriminator': {'propertyName': 'channel'},
    });
  });
}
