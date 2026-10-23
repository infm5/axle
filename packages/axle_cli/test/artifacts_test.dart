import 'dart:convert';

import 'package:axle_cli/axle_cli.dart';
import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('generateJsonArtifact', () {
    test('serializes the document with a trailing newline', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(title: 'Test', version: '1.0.0'),
      );
      final artifact = generateJsonArtifact(document);

      expect(artifact, endsWith('\n'));
      expect(jsonDecode(artifact), document.toJson());
    });
  });

  group('generateYamlArtifact', () {
    test('serializes the same data as the JSON artifact', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(
          title: 'Test API',
          version: '1.0.0',
          description: 'A test API.',
          contact: OpenApiContact(email: 'api@example.com'),
        ),
        paths: const {
          '/users': OpenApiPathItem({
            'get': OpenApiOperation(
              tags: ['Users'],
              parameters: [
                OpenApiParameter(
                  name: 'id',
                  location: OpenApiParameterLocation.path,
                  required: true,
                  schema: OpenApiSchema.integer(),
                ),
              ],
              responses: {'200': OpenApiResponse(description: 'OK')},
            ),
          }),
        },
      );

      final yaml = generateYamlArtifact(document);
      final decoded = loadYaml(yaml);

      expect(yaml, endsWith('\n'));
      expect(_toPlain(decoded), document.toJson());
    });
  });

  group('generateDartArtifact', () {
    test('emits a const string with escaped JSON', () {
      final source = generateDartArtifact('{"message":"it\'s \$5\\nnext"}');

      expect(source, contains('const String axleOpenApiJson ='));
      expect(source, contains(r"it\'s"));
      expect(source, contains(r'\$5'));
      expect(source, contains(r'\nnext'));
      expect(source, contains('GENERATED CODE'));
    });

    test('preserves unicode', () {
      final source = generateDartArtifact('{"value":"héllo ✓"}');
      expect(source, contains('héllo ✓'));
    });

    test('escapes carriage returns, tabs, and control characters', () {
      final source = generateDartArtifact('a\rb\tc\u0001');

      expect(source, contains(r'\r'));
      expect(source, contains(r'\t'));
      expect(source, contains(r'\u{1}'));
    });
  });
}

Object? _toPlain(Object? value) {
  if (value is YamlMap) {
    return {
      for (final entry in value.entries) entry.key: _toPlain(entry.value),
    };
  }
  if (value is YamlList) return [for (final item in value) _toPlain(item)];
  return value;
}
