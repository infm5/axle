import 'dart:convert';

import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  _exampleAndStyleTests();

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

    test('serializes tags, terms, and external docs', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(
          title: 'Documented API',
          version: '1.0.0',
          termsOfService: 'https://example.com/terms',
        ),
        tags: const [
          OpenApiTag(
            name: 'Users',
            description: 'User operations.',
            externalDocs: OpenApiExternalDocs(url: 'https://example.com/users'),
          ),
        ],
        externalDocs: const OpenApiExternalDocs(
          url: 'https://example.com/docs',
          description: 'Full docs.',
        ),
      );

      expect(document.toJson()['info'], {
        'title': 'Documented API',
        'version': '1.0.0',
        'termsOfService': 'https://example.com/terms',
      });
      expect(document.toJson()['tags'], [
        {
          'name': 'Users',
          'description': 'User operations.',
          'externalDocs': {'url': 'https://example.com/users'},
        },
      ]);
      expect(document.toJson()['externalDocs'], {
        'url': 'https://example.com/docs',
        'description': 'Full docs.',
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

void _exampleAndStyleTests() {
  group('named examples and parameter style', () {
    test('OpenApiExample serializes inline and external values', () {
      expect(const OpenApiExample(value: {'a': 1}, summary: 'S').toJson(), {
        'summary': 'S',
        'value': {'a': 1},
      });
      expect(const OpenApiExample.external('https://x/y.json').toJson(), {
        'externalValue': 'https://x/y.json',
      });
    });

    test('OpenApiMediaType writes examples next to the schema', () {
      expect(
        const OpenApiMediaType(
          schema: OpenApiSchema.string(),
          examples: {'one': OpenApiExample(value: 'a')},
        ).toJson(),
        {
          'schema': {'type': 'string'},
          'examples': {
            'one': {'value': 'a'},
          },
        },
      );
    });

    test('OpenApiParameter writes style, explode, and examples', () {
      final json =
          const OpenApiParameter(
            name: 'ids',
            location: OpenApiParameterLocation.query,
            schema: OpenApiSchema.array(OpenApiSchema.integer()),
            style: 'pipeDelimited',
            explode: false,
            examples: {
              'two': OpenApiExample(value: [1, 2]),
            },
          ).toJson();
      expect(json['style'], 'pipeDelimited');
      expect(json['explode'], false);
      expect(json['examples'], {
        'two': {
          'value': [1, 2],
        },
      });
    });
  });

  test('OpenApiHeader writes its example', () {
    expect(
      const OpenApiHeader(
        schema: OpenApiSchema.string(),
        description: 'Cache validator.',
        example: '"v1"',
      ).toJson(),
      {
        'description': 'Cache validator.',
        'schema': {'type': 'string'},
        'example': '"v1"',
      },
    );
  });

  test('ApiResponse range and default keys', () {
    expect(const ApiResponse.range(4).key, '4XX');
    expect(const ApiResponse.defaultResponse().key, 'default');
    expect(const ApiResponse.defaultResponse().status, 0);
    expect(
      const ApiResponse.range(
        5,
        contentTypes: ['application/problem+json'],
      ).contentTypes,
      ['application/problem+json'],
    );
    expect(const ApiResponse.ok().key, isNull);
    expect(const ApiResponse.conflict().status, 409);
  });
}
