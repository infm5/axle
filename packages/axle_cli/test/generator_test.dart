import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:axle_core/axle_core.dart';
import 'package:test/test.dart';

void main() {
  late AxleConfig config;
  late GeneratedSpec result;
  late Map<String, Object?> json;
  late Map<String, Object?> paths;
  late Map<String, Object?> schemas;

  setUpAll(() async {
    config = AxleConfig(
      title: 'Test API',
      version: '1.2.3',
      description: 'API used by the generator tests.',
      contact: const OpenApiContact(name: 'API Team', email: 'api@example.com'),
      license: const OpenApiLicense(name: 'MIT', identifier: 'MIT'),
      scan: const ['test/fixtures/api.dart'],
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

  test('writes document metadata', () {
    expect(json['openapi'], '3.1.0');
    expect(json['info'], {
      'title': 'Test API',
      'version': '1.2.3',
      'description': 'API used by the generator tests.',
      'contact': {'name': 'API Team', 'email': 'api@example.com'},
      'license': {'name': 'MIT', 'identifier': 'MIT'},
    });
    expect(json.containsKey('servers'), isFalse);
  });

  test('groups operations by normalized path', () {
    expect(paths.keys, ['/users', '/users/{id}']);
    expect((paths['/users']! as Map).keys, ['get', 'post']);
  });

  test('builds path parameters and responses', () {
    final operation = (paths['/users/{id}']! as Map)['get'] as Map;
    expect(operation['operationId'], 'getUser');
    expect(operation['summary'], 'Get a user');
    expect(operation['tags'], ['Users']);
    expect(operation['parameters'], [
      {
        'name': 'id',
        'in': 'path',
        'description': 'The user id.',
        'required': true,
        'schema': {'type': 'integer'},
      },
    ]);
    final responses = operation['responses'] as Map;
    expect(responses['200']['content']['application/json']['schema'], {
      r'$ref': '#/components/schemas/UserDto',
    });
    expect(responses['404'], {'description': 'Not Found'});
  });

  test('builds request bodies', () {
    final operation = (paths['/users']! as Map)['post'] as Map;
    expect(operation['operationId'], 'createUser');
    expect(operation['requestBody']['required'], true);
    expect(operation['requestBody']['content']['application/json']['schema'], {
      r'$ref': '#/components/schemas/CreateUserDto',
    });
    expect(
      operation['responses']['201']['content']['application/json']['schema'],
      {r'$ref': '#/components/schemas/UserDto'},
    );
  });

  test('builds query parameters and array responses', () {
    final operation = (paths['/users']! as Map)['get'] as Map;
    final parameters = operation['parameters'] as List;
    expect(parameters, hasLength(2));
    expect(parameters[0], {
      'name': 'limit',
      'in': 'query',
      'description': 'Maximum number of users.',
      'required': false,
      'schema': {'type': 'integer', 'default': 20},
    });
    expect(parameters[1], {
      'name': 'role',
      'in': 'query',
      'required': false,
      'schema': {
        'type': 'string',
        'enum': ['admin', 'member'],
      },
    });
    expect(
      operation['responses']['200']['content']['application/json']['schema'],
      {
        'type': 'array',
        'items': {r'$ref': '#/components/schemas/UserDto'},
      },
    );
  });

  test('infers DTO schemas, JSON keys, and nested classes', () {
    expect(schemas.keys, [
      'AddressDto',
      'CreateUserDto',
      'HealthDto',
      'UserDto',
    ]);

    final user = schemas['UserDto']! as Map;
    expect(user['description'], 'A user returned by the API.');
    final properties = user['properties'] as Map;
    expect(properties.keys, [
      'address',
      'created_at',
      'display_name',
      'id',
      'role',
      'scores',
      'tags',
    ]);
    expect(properties['id'], {
      'type': 'integer',
      'description': 'The numeric user id.',
    });
    expect(properties['display_name'], {
      'type': 'string',
      'description': 'The public display name.',
    });
    expect(properties['role'], {
      'type': 'string',
      'enum': ['admin', 'member'],
    });
    expect(properties['created_at'], {'type': 'string', 'format': 'date-time'});
    expect(properties['tags'], {
      'type': 'array',
      'items': {'type': 'string'},
    });
    expect(properties['scores'], {
      'type': 'object',
      'additionalProperties': {'type': 'integer'},
    });
    expect(properties['address'], {
      'anyOf': [
        {r'$ref': '#/components/schemas/AddressDto'},
        {'type': 'null'},
      ],
    });
    expect(user['required'], [
      'created_at',
      'display_name',
      'id',
      'role',
      'scores',
      'tags',
    ]);

    final address = schemas['AddressDto']! as Map;
    expect(address['required'], ['city']);

    final createUser = schemas['CreateUserDto']! as Map;
    expect(createUser['required'], ['name']);
    expect(createUser['properties']['role'], {
      'type': 'string',
      'enum': ['admin', 'member'],
    });
  });

  test('produces a valid JSON string', () {
    final encoded = result.document.toJsonString();
    expect(encoded, startsWith('{\n  "openapi": "3.1.0"'));
    expect(encoded, endsWith('}'));
    expect(generateJsonArtifact(result.document), endsWith('}\n'));
  });

  test('is deterministic across runs', () async {
    final second = await OpenApiGenerator(
      config: config,
      projectRoot: Directory.current,
    ).generate();
    expect(second.document.toJsonString(), result.document.toJsonString());
  });
}
