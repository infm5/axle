import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> schemas;
  late List<String> warnings;

  setUpAll(() async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Sealed',
        version: '1.0.0',
        scan: const ['test/fixtures/sealed'],
      ),
      projectRoot: Directory.current,
    ).generate();
    warnings = result.warnings;
    final components =
        result.document.toJson()['components']! as Map<String, Object?>;
    schemas = components['schemas']! as Map<String, Object?>;
  });

  Map<String, Object?> ref(String name) => {
    r'$ref': '#/components/schemas/$name',
  };

  test('turns a sealed class into oneOf of its subtypes', () {
    expect(schemas['Shape'], {
      'oneOf': [ref('Circle'), ref('Square')],
    });
  });

  test('subtypes include fields inherited from the sealed base', () {
    final circle = schemas['Circle']! as Map;
    expect((circle['properties']! as Map).keys, ['label', 'radius']);
  });

  test('omits subtypes marked ignore', () {
    expect(schemas.keys, isNot(contains('Secret')));
  });

  test('adds an opt-in discriminator with its mapping', () {
    expect(schemas['Pet'], {
      'description': 'A pet.',
      'oneOf': [ref('Cat'), ref('Dog')],
      'discriminator': {
        'propertyName': 'kind',
        'mapping': {
          'dog': '#/components/schemas/Dog',
          'cat': '#/components/schemas/Cat',
        },
      },
    });
  });

  test('expands nested sealed hierarchies', () {
    expect(schemas['Event'], {
      'oneOf': [ref('SystemEvent'), ref('UserEvent')],
    });
    expect(schemas['UserEvent'], {
      'oneOf': [ref('UserCreated'), ref('UserDeleted')],
    });
  });

  test('warns about sealed classes without a discriminator', () {
    expect(
      warnings,
      contains(startsWith('Sealed class Shape becomes a oneOf without a')),
    );
    expect(
      warnings,
      contains(startsWith('Sealed class Event becomes a oneOf without a')),
    );
    expect(warnings.where((w) => w.startsWith('Sealed class Pet')), isEmpty);
  });

  test('warns when a variant does not declare the discriminator property', () {
    expect(
      warnings,
      contains(
        startsWith('Discriminator property `kind` of Pet is not declared by '),
      ),
    );
  });
}
