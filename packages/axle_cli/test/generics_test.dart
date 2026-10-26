import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> schemas;

  setUpAll(() async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Generics',
        version: '1.0.0',
        scan: const ['test/fixtures/generics'],
      ),
      projectRoot: Directory.current,
    ).generate();
    final components =
        result.document.toJson()['components']! as Map<String, Object?>;
    schemas = components['schemas']! as Map<String, Object?>;
  });

  Map<String, Object?> properties(String name) =>
      (schemas[name]! as Map)['properties']! as Map<String, Object?>;

  test('registers one schema per instantiation', () {
    expect(
      schemas.keys,
      containsAll([
        'Page_UserDto',
        'Page_Item',
        'Page_String',
        'Envelope_Page_UserDto',
        'Pair_UserDto_List_int',
        'Audited_Item',
        'UserPage',
        'Tree_int',
      ]),
    );
    expect(schemas.keys, isNot(contains('Page')));
  });

  test('substitutes type arguments into fields', () {
    expect(properties('Page_UserDto')['items'], {
      'type': 'array',
      'items': {r'$ref': '#/components/schemas/UserDto'},
    });
    expect(properties('Page_String')['items'], {
      'type': 'array',
      'items': {'type': 'string'},
    });
    expect(properties('Page_String')['next'], {
      'type': ['string', 'null'],
    });
    expect(properties('Pair_UserDto_List_int')['second'], {
      'type': 'array',
      'items': {'type': 'integer'},
    });
  });

  test('keeps the description of the generic class', () {
    expect(
      (schemas['Page_UserDto']! as Map)['description'],
      'A page of results.',
    );
    expect(
      (schemas['Page_String']! as Map)['description'],
      'A page of results.',
    );
  });

  test('resolves nested generics and inherited generic fields', () {
    expect(properties('Envelope_Page_UserDto')['data'], {
      r'$ref': '#/components/schemas/Page_UserDto',
    });
    expect(properties('Audited_Item').keys, ['by', 'data', 'meta']);
    expect(properties('Audited_Item')['meta'], {
      'type': 'object',
      'additionalProperties': {r'$ref': '#/components/schemas/Item'},
    });
    expect(properties('UserPage')['items'], {
      'type': 'array',
      'items': {r'$ref': '#/components/schemas/UserDto'},
    });
  });

  test('handles self-referencing generics', () {
    expect(properties('Tree_int')['children'], {
      'type': 'array',
      'items': {r'$ref': '#/components/schemas/Tree_int'},
    });
  });
}
