import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> paths;

  setUpAll(() async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Contract',
        version: '1.0.0',
        scan: const ['test/fixtures/contract'],
      ),
      projectRoot: Directory.current,
    ).generate();
    paths = result.document.toJson()['paths']! as Map<String, Object?>;
  });

  Map<String, Object?> operation(String path, String method) =>
      (paths[path]! as Map)[method]! as Map<String, Object?>;

  Map<String, Object?> parameter(String path, String name) {
    final parameters = operation(path, 'get')['parameters']! as List;
    return parameters.cast<Map<String, Object?>>().firstWhere(
      (parameter) => parameter['name'] == name,
    );
  }

  group('responses', () {
    test('lists exact codes, then ranges, then default', () {
      final responses = operation('/items', 'get')['responses']! as Map;
      expect(responses.keys, [
        '200',
        '401',
        '403',
        '409',
        '422',
        '429',
        '4XX',
        '5XX',
        'default',
      ]);
    });

    test('spreads a shared const list of errors into the annotation', () {
      final responses = operation('/items', 'get')['responses']! as Map;
      for (final code in ['401', '403', '429']) {
        expect(
          ((responses[code]! as Map)['content']! as Map)['application/json'],
          {
            'schema': {r'$ref': '#/components/schemas/ApiError'},
          },
        );
      }
    });

    test('describes ranges and default without a description', () {
      final responses = operation('/items', 'get')['responses']! as Map;
      expect((responses['4XX']! as Map)['description'], 'Client error');
      expect((responses['5XX']! as Map)['description'], 'Server error');
      expect((responses['5XX']! as Map).containsKey('content'), isFalse);
      expect((responses['default']! as Map)['description'], 'Unexpected error');
    });

    test('keeps the standard descriptions of the new shortcuts', () {
      final responses = operation('/items', 'get')['responses']! as Map;
      expect((responses['401']! as Map)['description'], 'Unauthorized');
      expect((responses['422']! as Map)['description'], 'Unprocessable Entity');
      expect((responses['429']! as Map)['description'], 'Too Many Requests');
    });
  });

  group('parameter style and explode', () {
    test('omits values that equal the OpenAPI default', () {
      final tags = parameter('/items', 'tags');
      expect(tags.containsKey('style'), isFalse);
      expect(tags.containsKey('explode'), isFalse);
    });

    test('writes explode: false for a comma-separated list', () {
      expect(parameter('/items', 'ids')['explode'], false);
      expect(parameter('/items', 'ids').containsKey('style'), isFalse);
    });

    test('writes non-default styles', () {
      expect(parameter('/items', 'sort')['style'], 'pipeDelimited');
      expect(parameter('/items', 'sort').containsKey('explode'), isFalse);
      expect(parameter('/items', 'filter')['style'], 'deepObject');
      expect(parameter('/items/{id}', 'id')['style'], 'label');
    });

    test('writes explode: true where the style defaults to false', () {
      expect(parameter('/items', 'X-Ids')['explode'], true);
    });
  });

  group('named examples', () {
    test('writes parameter examples and no single example', () {
      final q = parameter('/items', 'q');
      expect(q.containsKey('example'), isFalse);
      expect(q['examples'], {
        'word': {'summary': 'One word', 'value': 'cat'},
        'phrase': {'description': 'Several words.', 'value': 'black cat'},
      });
    });

    test('writes request body examples, including an external one', () {
      final content =
          ((operation('/items', 'post')['requestBody']! as Map)['content']!
                  as Map)['application/json']!
              as Map;
      expect(content['examples'], {
        'minimal': {
          'summary': 'Smallest',
          'value': {'id': 1, 'name': 'Lamp'},
        },
        'external': {'externalValue': 'https://example.com/item.json'},
      });
    });

    test('writes response examples', () {
      final content =
          (((operation('/items', 'post')['responses']! as Map)['201']!
                      as Map)['content']!
                  as Map)['application/json']!
              as Map;
      expect(content['examples'], {
        'created': {
          'value': {'id': 2, 'name': 'Desk'},
        },
      });
    });
  });
}
