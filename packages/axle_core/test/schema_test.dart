import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiSchema', () {
    test('serializes primitives', () {
      expect(const OpenApiSchema.any().toJson(), isEmpty);
      expect(const OpenApiSchema.integer().toJson(), {'type': 'integer'});
      expect(const OpenApiSchema.number(format: 'double').toJson(), {
        'type': 'number',
        'format': 'double',
      });
      expect(const OpenApiSchema.boolean().toJson(), {'type': 'boolean'});
      expect(const OpenApiSchema.dateTime().toJson(), {
        'type': 'string',
        'format': 'date-time',
      });
      expect(const OpenApiSchema.uri().toJson(), {
        'type': 'string',
        'format': 'uri',
      });
      expect(const OpenApiSchema.duration().toJson(), {
        'type': 'string',
        'format': 'duration',
      });
    });

    test('serializes unconstrained schema metadata', () {
      expect(
        const OpenApiSchema.any(
          description: 'Any JSON value.',
          example: {'ok': true},
        ).toJson(),
        {
          'description': 'Any JSON value.',
          'example': {'ok': true},
        },
      );
    });

    test('serializes arrays and objects', () {
      final schema = const OpenApiSchema.object(
        properties: {
          'id': OpenApiSchema.integer(),
          'tags': OpenApiSchema.array(OpenApiSchema.string()),
        },
        requiredProperties: ['id'],
        additionalProperties: false,
      );

      expect(schema.toJson(), {
        'type': 'object',
        'properties': {
          'id': {'type': 'integer'},
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['id'],
        'additionalProperties': false,
      });
    });

    test('serializes maps with additionalProperties schemas', () {
      final schema = OpenApiSchema.object(
        additionalProperties: const OpenApiSchema.integer(),
      );

      expect(schema.toJson(), {
        'type': 'object',
        'additionalProperties': {'type': 'integer'},
      });
    });

    test('serializes refs', () {
      expect(const OpenApiSchema.ref('UserDto').toJson(), {
        r'$ref': '#/components/schemas/UserDto',
      });
    });

    test('serializes nullable refs with anyOf', () {
      expect(const OpenApiSchema.ref('UserDto').asNullable().toJson(), {
        'anyOf': [
          {r'$ref': '#/components/schemas/UserDto'},
          {'type': 'null'},
        ],
      });
    });

    test('serializes nullable primitives as a type list', () {
      expect(const OpenApiSchema.string().asNullable().toJson(), {
        'type': ['string', 'null'],
      });
    });

    test('adds null to nullable enums', () {
      expect(const OpenApiSchema.enumString(['a', 'b']).asNullable().toJson(), {
        'type': ['string', 'null'],
        'enum': ['a', 'b', null],
      });
    });

    test('adds a null schema to nullable oneOf schemas', () {
      expect(
        const OpenApiSchema.oneOf([
          OpenApiSchema.string(),
          OpenApiSchema.integer(),
        ]).asNullable().toJson(),
        {
          'oneOf': [
            {'type': 'string'},
            {'type': 'integer'},
            {'type': 'null'},
          ],
        },
      );
    });

    test('serializes oneOf discriminators', () {
      expect(
        const OpenApiSchema.oneOf(
          [OpenApiSchema.ref('Cat'), OpenApiSchema.ref('Dog')],
          discriminator: OpenApiDiscriminator(
            'kind',
            mapping: {'cat': 'Cat', 'dog': 'Dog'},
          ),
        ).toJson(),
        {
          'oneOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {r'$ref': '#/components/schemas/Dog'},
          ],
          'discriminator': {
            'propertyName': 'kind',
            'mapping': {
              'cat': '#/components/schemas/Cat',
              'dog': '#/components/schemas/Dog',
            },
          },
        },
      );
    });

    test('preserves metadata on refs', () {
      expect(
        const OpenApiSchema.ref(
          'UserDto',
          description: 'A user',
          example: {'id': 1},
        ).toJson(),
        {
          r'$ref': '#/components/schemas/UserDto',
          'description': 'A user',
          'example': {'id': 1},
        },
      );
      expect(const OpenApiSchema.ref('other/User').toJson(), {
        r'$ref': 'other/User',
      });
    });

    test('copies schemas while replacing one field', () {
      const base = OpenApiSchema.object(
        properties: {'id': OpenApiSchema.integer()},
        requiredProperties: ['id'],
        additionalProperties: false,
        description: 'Old description.',
        example: {'id': 1},
        defaultValue: {'id': 2},
      );

      expect(base.withDescription('New description.').toJson(), {
        'type': 'object',
        'properties': {
          'id': {'type': 'integer'},
        },
        'required': ['id'],
        'additionalProperties': false,
        'description': 'New description.',
        'example': {'id': 1},
        'default': {'id': 2},
      });
      expect(base.withExample({'id': 3}).toJson(), {
        'type': 'object',
        'properties': {
          'id': {'type': 'integer'},
        },
        'required': ['id'],
        'additionalProperties': false,
        'description': 'Old description.',
        'example': {'id': 3},
        'default': {'id': 2},
      });
      expect(base.withDefaultValue({'id': 4}).toJson(), {
        'type': 'object',
        'properties': {
          'id': {'type': 'integer'},
        },
        'required': ['id'],
        'additionalProperties': false,
        'description': 'Old description.',
        'example': {'id': 1},
        'default': {'id': 4},
      });
    });
  });
}
