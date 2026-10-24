import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiSecurityScheme', () {
    test('serializes HTTP bearer schemes', () {
      expect(
        const OpenApiSecurityScheme.httpBearer(bearerFormat: 'JWT').toJson(),
        {'type': 'http', 'scheme': 'bearer', 'bearerFormat': 'JWT'},
      );
    });

    test('serializes API key schemes', () {
      expect(
        const OpenApiSecurityScheme.apiKey(
          name: 'X-API-Key',
          location: 'header',
          description: 'Service key.',
        ).toJson(),
        {
          'type': 'apiKey',
          'description': 'Service key.',
          'name': 'X-API-Key',
          'in': 'header',
        },
      );
    });

    test('serializes OAuth2 flows and scopes', () {
      expect(
        const OpenApiSecurityScheme(
          type: 'oauth2',
          flows: OpenApiOAuthFlows(
            authorizationCode: OpenApiOAuthFlow(
              authorizationUrl: 'https://example.com/authorize',
              tokenUrl: 'https://example.com/token',
              scopes: {'read': 'Read access'},
            ),
          ),
        ).toJson(),
        {
          'type': 'oauth2',
          'flows': {
            'authorizationCode': {
              'authorizationUrl': 'https://example.com/authorize',
              'tokenUrl': 'https://example.com/token',
              'scopes': {'read': 'Read access'},
            },
          },
        },
      );
    });
  });

  group('OpenApiDocument security', () {
    test('serializes document security and schemes', () {
      final document = OpenApiDocument(
        info: const OpenApiInfo(title: 'Secure', version: '1.0.0'),
        security: const [
          OpenApiSecurityRequirement({'bearerAuth': []}),
        ],
        components: const OpenApiComponents(
          securitySchemes: {'bearerAuth': OpenApiSecurityScheme.httpBearer()},
        ),
      );

      expect(document.toJson()['security'], [
        {'bearerAuth': <Object?>[]},
      ]);
      expect((document.toJson()['components'] as Map)['securitySchemes'], {
        'bearerAuth': {'type': 'http', 'scheme': 'bearer'},
      });
    });

    test('serializes operation security overrides', () {
      const operation = OpenApiOperation(responses: {}, security: []);
      expect(operation.toJson()['security'], isEmpty);
      expect(
        const OpenApiOperation(responses: {}).toJson(),
        isNot(contains('security')),
      );
    });
  });

  group('OpenApi response and request content', () {
    test('serializes response headers and multiple media types', () {
      const response = OpenApiResponse(
        description: 'OK',
        content: {
          'application/json': OpenApiMediaType(schema: OpenApiSchema.object()),
          'application/problem+json': OpenApiMediaType(
            schema: OpenApiSchema.object(),
          ),
        },
        headers: {
          'X-RateLimit': OpenApiHeader(
            schema: OpenApiSchema.integer(),
            description: 'Remaining requests.',
            required: true,
          ),
        },
      );

      expect(response.toJson(), {
        'description': 'OK',
        'headers': {
          'X-RateLimit': {
            'description': 'Remaining requests.',
            'required': true,
            'schema': {'type': 'integer'},
          },
        },
        'content': {
          'application/json': {
            'schema': {'type': 'object'},
          },
          'application/problem+json': {
            'schema': {'type': 'object'},
          },
        },
      });
    });

    test('keeps the JSON convenience shape for request bodies', () {
      const body = OpenApiRequestBody(schema: OpenApiSchema.string());
      expect(body.toJson(), {
        'required': true,
        'content': {
          'application/json': {
            'schema': {'type': 'string'},
          },
        },
      });
    });
  });
}
