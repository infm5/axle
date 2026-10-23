import 'dart:convert';

import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiDocument', () {
    test('serializes paths, operations, and components', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(
          title: 'Users API',
          version: '1.2.3',
          description: 'A users API.',
          contact: OpenApiContact(name: 'API Team', email: 'api@example.com'),
          license: OpenApiLicense(name: 'MIT', identifier: 'MIT'),
        ),
        servers: const [OpenApiServer(url: 'http://localhost:8080')],
        paths: const {
          '/users/{id}': OpenApiPathItem({
            'get': OpenApiOperation(
              operationId: 'getUser',
              summary: 'Get a user',
              tags: ['Users'],
              parameters: [
                OpenApiParameter(
                  name: 'id',
                  location: OpenApiParameterLocation.path,
                  required: true,
                  schema: OpenApiSchema.integer(),
                ),
              ],
              responses: {
                '200': OpenApiResponse(
                  description: 'OK',
                  schema: OpenApiSchema.ref('#/components/schemas/UserDto'),
                ),
              },
            ),
          }),
        },
        components: const OpenApiComponents(
          schemas: {
            'UserDto': OpenApiSchema.object(
              properties: {
                'id': OpenApiSchema.integer(),
                'name': OpenApiSchema.string(),
              },
              requiredProperties: ['id', 'name'],
            ),
          },
        ),
      );

      final json = document.toJson();

      expect(json['openapi'], '3.1.0');
      expect(json['info'], {
        'title': 'Users API',
        'version': '1.2.3',
        'description': 'A users API.',
        'contact': {'name': 'API Team', 'email': 'api@example.com'},
        'license': {'name': 'MIT', 'identifier': 'MIT'},
      });
      expect(json['servers'], [
        {'url': 'http://localhost:8080'},
      ]);
      expect((json['paths'] as Map)['/users/{id}']['get']['parameters'], [
        {
          'name': 'id',
          'in': 'path',
          'required': true,
          'schema': {'type': 'integer'},
        },
      ]);
      expect((json['components'] as Map)['schemas']['UserDto'], {
        'type': 'object',
        'properties': {
          'id': {'type': 'integer'},
          'name': {'type': 'string'},
        },
        'required': ['id', 'name'],
      });
    });

    test('omits empty components and servers', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(title: 'Empty API', version: '1.0.0'),
      );

      expect(document.toJson(), {
        'openapi': '3.1.0',
        'info': {'title': 'Empty API', 'version': '1.0.0'},
        'paths': <String, Object?>{},
      });
    });

    test('produces pretty JSON with a trailing newline when requested', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(title: 'Pretty', version: '1.0.0'),
      );

      final encoded = document.toJsonString();
      expect(encoded, contains('\n  "info": {'));
      expect(jsonDecode(encoded), document.toJson());
    });
  });
}
