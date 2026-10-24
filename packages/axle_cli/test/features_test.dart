import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  late GeneratedSpec result;
  late Map<String, Object?> json;
  late Map<String, Object?> paths;
  late Map<String, Object?> schemas;

  setUpAll(() async {
    final config = AxleConfig(
      title: 'Protected API',
      version: '1.0.0',
      termsOfService: 'https://example.com/terms',
      tags: const [
        OpenApiTag(
          name: 'Secure',
          description: 'Protected endpoints.',
          externalDocs: OpenApiExternalDocs(
            url: 'https://example.com/secure-docs',
          ),
        ),
      ],
      externalDocs: const OpenApiExternalDocs(
        url: 'https://example.com/docs',
        description: 'API documentation.',
      ),
      servers: const [
        OpenApiServer(
          url: 'https://api.example.com',
          description: 'Production.',
        ),
      ],
      scan: const ['test/fixtures/features.dart'],
      securitySchemes: const {
        'bearerAuth': OpenApiSecurityScheme.httpBearer(bearerFormat: 'JWT'),
        'oauth2': OpenApiSecurityScheme(
          type: 'oauth2',
          flows: OpenApiOAuthFlows(
            clientCredentials: OpenApiOAuthFlow(
              tokenUrl: 'https://auth.example.com/token',
              scopes: {'write': 'Write access'},
            ),
          ),
        ),
      },
      defaultSecurity: const ['bearerAuth'],
    );
    result = await OpenApiGenerator(
      config: config,
      projectRoot: Directory.current,
    ).generate();
    json = result.document.toJson();
    paths = json['paths']! as Map<String, Object?>;
    schemas =
        (json['components']! as Map<String, Object?>)['schemas']!
            as Map<String, Object?>;
  });

  test('writes global metadata', () {
    final info = json['info']! as Map;
    expect(info['termsOfService'], 'https://example.com/terms');
    expect(json['tags'], [
      {
        'name': 'Secure',
        'description': 'Protected endpoints.',
        'externalDocs': {'url': 'https://example.com/secure-docs'},
      },
    ]);
    expect(json['externalDocs'], {
      'url': 'https://example.com/docs',
      'description': 'API documentation.',
    });
    expect(json['servers'], [
      {'url': 'https://api.example.com', 'description': 'Production.'},
    ]);
  });

  test('writes document security and components', () {
    expect(json['security'], [
      {'bearerAuth': <Object?>[]},
    ]);
    expect(
      (json['components']! as Map)['securitySchemes'],
      containsPair('bearerAuth', {
        'type': 'http',
        'scheme': 'bearer',
        'bearerFormat': 'JWT',
      }),
    );
    expect((json['components']! as Map)['securitySchemes']['oauth2'], {
      'type': 'oauth2',
      'flows': {
        'clientCredentials': {
          'tokenUrl': 'https://auth.example.com/token',
          'scopes': {'write': 'Write access'},
        },
      },
    });
  });

  test('writes operation security and public overrides', () {
    expect((paths['/secure/{id}']! as Map)['get']['security'], [
      {'bearerAuth': <Object?>[]},
    ]);
    expect((paths['/secure']! as Map)['post']['security'], [
      {
        'oauth2': ['write'],
      },
    ]);
    expect((paths['/public']! as Map)['get']['security'], isEmpty);
    expect(
      ((paths['/pet']! as Map)['get'] as Map).containsKey('security'),
      isFalse,
    );
  });

  test('writes response headers and content types', () {
    final response = (paths['/secure/{id}']! as Map)['get']['responses']['200'];
    expect(response['headers'], {
      'X-RateLimit': {
        'description': 'Remaining requests.',
        'required': true,
        'schema': {'type': 'integer'},
      },
    });
    expect(response['content'].keys, [
      'application/json',
      'application/problem+json',
    ]);
  });

  test('writes cookie, query, header, and path constraints', () {
    final parameters =
        (paths['/secure/{id}']! as Map)['get']['parameters'] as List;
    expect(
      parameters,
      contains(
        equals({
          'name': 'id',
          'in': 'path',
          'required': true,
          'schema': {
            'type': 'integer',
            'format': 'int64',
            'minimum': 1,
            'maximum': 999,
          },
        }),
      ),
    );
    expect(
      parameters,
      contains(
        equals({
          'name': 'state',
          'in': 'query',
          'required': false,
          'schema': {
            'type': 'string',
            'enum': ['new', 'done'],
            'minLength': 2,
          },
        }),
      ),
    );
    expect(
      parameters,
      contains(
        equals({
          'name': 'X-Tenant',
          'in': 'header',
          'required': true,
          'schema': {'type': 'string', 'pattern': r'^[a-z0-9-]+$'},
        }),
      ),
    );
    expect(
      parameters,
      contains(
        equals({
          'name': 'session',
          'in': 'cookie',
          'required': true,
          'schema': {'type': 'string'},
        }),
      ),
    );
  });

  test('writes property constraints', () {
    final properties = (schemas['SecureDto']! as Map)['properties'] as Map;
    expect(properties['name'], {
      'type': 'string',
      'description': 'A constrained name.',
      'minLength': 3,
      'maxLength': 20,
      'pattern': r'^[a-z]+$',
    });
    expect(properties['count'], {
      'type': 'integer',
      'enum': [1, 2, 3],
      'minimum': 1,
      'maximum': 100,
    });
  });

  test('writes binary multipart uploads', () {
    expect((schemas['UploadDto']! as Map)['properties']['file'], {
      'type': 'string',
      'format': 'binary',
    });
    expect((paths['/upload']! as Map)['post']['requestBody']['content'].keys, [
      'multipart/form-data',
    ]);
  });

  test('writes oneOf schemas with a discriminator', () {
    expect(schemas['PetDto'], {
      'oneOf': [
        {r'$ref': '#/components/schemas/CatDto'},
        {r'$ref': '#/components/schemas/DogDto'},
      ],
      'discriminator': {
        'propertyName': 'kind',
        'mapping': {
          'cat': '#/components/schemas/CatDto',
          'dog': '#/components/schemas/DogDto',
        },
      },
    });
  });

  test('writes request body content types', () {
    final body = (paths['/secure']! as Map)['post']['requestBody'];
    expect(body['content'].keys, [
      'application/json',
      'application/x-www-form-urlencoded',
    ]);
  });

  test('rejects unknown security schemes', () async {
    final config = AxleConfig(
      title: 'Protected API',
      version: '1.0.0',
      scan: const ['test/fixtures/features.dart'],
    );
    expect(
      () => OpenApiGenerator(
        config: config,
        projectRoot: Directory.current,
      ).generate(),
      throwsA(
        isA<AxleException>()
            .having((error) => error.exitCode, 'exitCode', 65)
            .having(
              (error) => error.message,
              'message',
              contains('unknown security scheme `bearerAuth`'),
            ),
      ),
    );
  });
}
