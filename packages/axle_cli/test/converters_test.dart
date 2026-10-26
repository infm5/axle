import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> schemas;
  late List<String> warnings;

  setUpAll(() async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Converters',
        version: '1.0.0',
        scan: const ['test/fixtures/converters'],
      ),
      projectRoot: Directory.current,
    ).generate();
    warnings = result.warnings;
    final components =
        result.document.toJson()['components']! as Map<String, Object?>;
    schemas = components['schemas']! as Map<String, Object?>;
  });

  Map<String, Object?> property(String schema, String name) =>
      ((schemas[schema]! as Map)['properties']! as Map)[name]!
          as Map<String, Object?>;

  test('uses the JSON type of a JsonConverter', () {
    expect(property('Event', 'at'), {'type': 'integer'});
  });

  test('keeps nullability when the converter changes the type', () {
    expect(property('Event', 'maybeAt'), {
      'type': ['integer', 'null'],
    });
  });

  test('uses the return type of @JsonKey(toJson:)', () {
    expect(property('Event', 'seen'), {'type': 'string'});
  });

  test('leaves converter-free fields on their Dart type', () {
    expect(property('Event', 'plain'), {
      'type': 'string',
      'format': 'date-time',
    });
  });

  test('applies a class-level converter to fields of its value type', () {
    expect(property('ClassLevel', 'when'), {'type': 'integer'});
    expect(property('ClassLevel', 'name'), {'type': 'string'});
  });

  test('lets @ApiProperty(type:) override the converter', () {
    expect(property('Event', 'priceText'), {
      'type': ['string', 'null'],
    });
  });

  test('warns when the converter hides the JSON type', () {
    expect(
      warnings,
      contains(startsWith('Property Event.price uses a custom converter')),
    );
    expect(warnings.where((w) => w.contains('Event.priceText')), isEmpty);
    expect(warnings.where((w) => w.contains('Event.at')), isEmpty);
  });
}
