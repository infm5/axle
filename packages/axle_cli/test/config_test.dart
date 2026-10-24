import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:axle_core/axle_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('normalizeOpenApiPath', () {
    test('converts Relic parameters', () {
      expect(normalizeOpenApiPath('/users/:id'), '/users/{id}');
      expect(
        normalizeOpenApiPath('users/:userId/posts/:postId'),
        '/users/{userId}/posts/{postId}',
      );
    });

    test('converts Shelf parameters and regex constraints', () {
      expect(normalizeOpenApiPath('/users/<id>'), '/users/{id}');
      expect(normalizeOpenApiPath(r'/users/<id|\d+>'), '/users/{id}');
    });

    test('keeps OpenAPI parameters', () {
      expect(normalizeOpenApiPath('/users/{id}'), '/users/{id}');
    });

    test('collapses duplicate slashes', () {
      expect(normalizeOpenApiPath('//users///:id'), '/users/{id}');
    });

    test('rejects empty and wildcard routes', () {
      expect(() => normalizeOpenApiPath('   '), throwsA(isA<AxleException>()));
      expect(
        () => normalizeOpenApiPath('/files/**'),
        throwsA(isA<AxleException>()),
      );
    });

    test('normalizes parameter annotation names', () {
      expect(normalizeParameterName(':id'), 'id');
      expect(normalizeParameterName('{id}'), 'id');
      expect(normalizeParameterName('<id>'), 'id');
      expect(normalizeParameterName('id'), 'id');
    });
  });

  group('AxleConfig', () {
    test('loads configuration from YAML', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      Directory(
        p.join(temp.path, 'packages', 'api', 'lib'),
      ).createSync(recursive: true);
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Users API
  version: 1.2.3
  description: A test API.
  contact:
    name: API Team
    email: api@example.com
  license:
    name: MIT
    identifier: MIT
generate:
  scan:
    - lib
    - packages/api/lib
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      final config = AxleConfig.load(temp);

      expect(config.openApiVersion, '3.1.0');
      expect(config.title, 'Users API');
      expect(config.version, '1.2.3');
      expect(config.description, 'A test API.');
      expect(config.contact?.name, 'API Team');
      expect(config.contact?.email, 'api@example.com');
      expect(config.license?.name, 'MIT');
      expect(config.license?.identifier, 'MIT');
      expect(config.scan, ['lib', 'packages/api/lib']);
      expect(config.jsonOutput, 'build/openapi.json');
      expect(config.swaggerUiOutput, 'assets/swagger-ui');
      expect(config.dartOutput, 'lib/src/generated/openapi.g.dart');
    });

    test('round-trips through toYamlString', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      Directory(p.join(temp.path, 'src')).createSync();
      final config = AxleConfig(
        title: 'Round Trip',
        version: '2.0.0',
        description: 'Escaped: "quotes" and \'apostrophes\'.',
        contact: const OpenApiContact(
          name: 'API Team',
          url: 'https://example.com',
        ),
        license: const OpenApiLicense(name: 'MIT', identifier: 'MIT'),
        scan: const ['lib', 'src'],
      );
      File(
        p.join(temp.path, AxleConfig.fileName),
      ).writeAsStringSync(config.toYamlString());

      final loaded = AxleConfig.load(temp);
      expect(loaded.title, config.title);
      expect(loaded.version, config.version);
      expect(loaded.description, config.description);
      expect(loaded.contact?.name, 'API Team');
      expect(loaded.license?.identifier, 'MIT');
      expect(loaded.scan, ['lib', 'src']);
    });

    test('loads global tag and documentation metadata', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Documented API
  version: 1.0.0
  termsOfService: https://example.com/terms
tags:
  - name: Users
    description: User operations.
    externalDocs:
      url: https://example.com/users
      description: User guide.
externalDocs:
  url: https://example.com/docs
  description: Full API docs.
servers:
  - url: https://api.example.com
    description: Production.
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      final config = AxleConfig.load(temp);
      expect(config.termsOfService, 'https://example.com/terms');
      expect(config.tags.single.name, 'Users');
      expect(config.tags.single.externalDocs?.url, 'https://example.com/users');
      expect(config.externalDocs?.description, 'Full API docs.');
      expect(config.servers.single.url, 'https://api.example.com');
    });

    test('rejects invalid tag metadata', () {
      final cases = <String, String>{
        'duplicate tags': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
tags:
  - name: Users
  - name: Users
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'tag without a name': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
tags:
  - description: Missing name.
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'external docs without a url': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
externalDocs:
  description: Missing URL.
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
      };
      _expectAllConfigFailures(cases, createLib: true);
    });

    test('loads security schemes and defaults', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bearer:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: Bearer tokens.
    api:
      type: apiKey
      in: header
      name: X-API-Key
    oauth:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/authorize
          tokenUrl: https://auth.example.com/token
          scopes:
            read: Read access
    oidc:
      type: openIdConnect
      openIdConnectUrl: https://auth.example.com/.well-known/openid-configuration
  default:
    - bearer
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      final config = AxleConfig.load(temp);

      expect(config.securitySchemes.keys, ['bearer', 'api', 'oauth', 'oidc']);
      expect(config.securitySchemes['bearer']?.type, 'http');
      expect(config.securitySchemes['bearer']?.scheme, 'bearer');
      expect(config.securitySchemes['bearer']?.bearerFormat, 'JWT');
      expect(config.securitySchemes['api']?.location, 'header');
      expect(
        config.securitySchemes['oauth']?.flows?.authorizationCode?.tokenUrl,
        'https://auth.example.com/token',
      );
      expect(
        config.securitySchemes['oidc']?.openIdConnectUrl,
        startsWith('https://auth.example.com'),
      );
      expect(config.defaultSecurity, ['bearer']);
    });

    test('round-trips security configuration', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      const config = AxleConfig(
        title: 'Secure API',
        version: '1.0.0',
        termsOfService: 'https://example.com/terms',
        tags: [
          OpenApiTag(
            name: 'Secure',
            description: 'Protected endpoints.',
            externalDocs: OpenApiExternalDocs(
              url: 'https://example.com/secure',
            ),
          ),
        ],
        externalDocs: OpenApiExternalDocs(
          url: 'https://example.com/docs',
          description: 'API docs.',
        ),
        servers: [OpenApiServer(url: 'https://api.example.com')],
        securitySchemes: {
          'bearer': OpenApiSecurityScheme.httpBearer(bearerFormat: 'JWT'),
          'api': OpenApiSecurityScheme.apiKey(
            name: 'X-API-Key',
            location: 'header',
          ),
          'oauth': OpenApiSecurityScheme(
            type: 'oauth2',
            flows: OpenApiOAuthFlows(
              password: OpenApiOAuthFlow(
                tokenUrl: 'https://auth.example.com/token',
                scopes: {'read': 'Read access'},
              ),
            ),
          ),
        },
        defaultSecurity: const ['bearer'],
      );
      File(
        p.join(temp.path, AxleConfig.fileName),
      ).writeAsStringSync(config.toYamlString());

      final loaded = AxleConfig.load(temp);
      expect(loaded.securitySchemes['bearer']?.scheme, 'bearer');
      expect(loaded.securitySchemes['api']?.name, 'X-API-Key');
      expect(
        loaded.securitySchemes['oauth']?.flows?.password?.tokenUrl,
        'https://auth.example.com/token',
      );
      expect(loaded.defaultSecurity, ['bearer']);
      expect(loaded.termsOfService, 'https://example.com/terms');
      expect(loaded.tags.single.name, 'Secure');
      expect(loaded.externalDocs?.url, 'https://example.com/docs');
      expect(loaded.servers.single.url, 'https://api.example.com');
    });

    test('rejects invalid security configuration', () {
      final cases = <String, String>{
        'unknown scheme type': '''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bad:
      type: magic
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'http without scheme': '''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bad:
      type: http
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'api key with invalid location': '''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bad:
      type: apiKey
      name: X-Key
      in: body
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'oauth with no flows': '''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bad:
      type: oauth2
      flows: {}
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'authorization code without token url': '''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bad:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://example.com/authorize
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'default references missing scheme': '''
openapi: 3.1.0
info:
  title: Secure API
  version: 1.0.0
security:
  schemes:
    bearer:
      type: http
      scheme: bearer
  default:
    - missing
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
      };
      _expectAllConfigFailures(cases, createLib: true);
    });

    test('rejects missing configuration', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));

      expect(
        () => AxleConfig.load(temp),
        throwsA(
          isA<AxleException>().having(
            (error) => error.exitCode,
            'exitCode',
            AxleExitCode.config,
          ),
        ),
      );
    });

    test('rejects non-3.1 documents', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.0.3
info:
  title: Old API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      expect(() => AxleConfig.load(temp), throwsA(isA<AxleException>()));
    });

    test('rejects unknown keys', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(p.join(temp.path, 'lib')).createSync();
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Old API
  version: 1.0.0
host: http://localhost:8080
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      expect(() => AxleConfig.load(temp), throwsA(isA<AxleException>()));
    });

    test('rejects paths outside the project root', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Users API
  version: 1.0.0
generate:
  scan: [../outside]
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      expect(() => AxleConfig.load(temp), throwsA(isA<AxleException>()));
    });

    test('requires generate.scan', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(p.join(temp.path, AxleConfig.fileName)).writeAsStringSync('''
openapi: 3.1.0
info:
  title: Users API
  version: 1.0.0
generate:
  output:
    json: build/openapi.json
    dart: lib/src/generated/openapi.g.dart
''');

      expect(() => AxleConfig.load(temp), throwsA(isA<AxleException>()));
    });
  });

  group('AxleConfig validation', () {
    test('rejects a non-map YAML document', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(
        p.join(temp.path, AxleConfig.fileName),
      ).writeAsStringSync('- not a map\n');

      expect(() => AxleConfig.load(temp), throwsA(_configError));
    });

    test('rejects missing and invalid info fields', () {
      final cases = <String, String>{
        'missing title': '''
openapi: 3.1.0
info:
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'invalid title': '''
openapi: 3.1.0
info:
  title: [42]
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'empty contact': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
  contact: {}
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'license without a name': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
  license:
    identifier: MIT
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
      };

      _expectAllConfigFailures(cases, createLib: true);
    });

    test('rejects non-map sections and missing output fields', () {
      final cases = <String, String>{
        'info is not a map': '''
openapi: 3.1.0
info: []
''',
        'generate is not a map': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate: []
''',
        'output is not a map': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output: []
''',
        'missing json output': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    dart: lib/openapi.g.dart
''',
        'scan is not a list': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: lib
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
      };

      _expectAllConfigFailures(cases, createLib: true);
    });

    test('rejects invalid scan paths', () {
      final cases = <String, String>{
        'empty scan list': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: []
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'non-string scan entry': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib, 42]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'missing scan path': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [missing]
  output:
    json: build/openapi.json
    dart: lib/openapi.g.dart
''',
      };

      _expectAllConfigFailures(cases, createLib: true);
    });

    test('rejects duplicate, root, and outside output paths', () {
      final cases = <String, String>{
        'duplicate outputs': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    dart: build/openapi.json
''',
        'duplicate ui output': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    ui: build/openapi.json
    dart: lib/openapi.g.dart
''',
        'outside ui output': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: build/openapi.json
    ui: ../swagger-ui
    dart: lib/openapi.g.dart
''',
        'project root output': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: .
    dart: lib/openapi.g.dart
''',
        'outside output': '''
openapi: 3.1.0
info:
  title: API
  version: 1.0.0
generate:
  scan: [lib]
  output:
    json: ../openapi.json
    dart: lib/openapi.g.dart
''',
      };

      _expectAllConfigFailures(cases, createLib: true);
    });

    test('writes optional contact and license fields', () {
      const config = AxleConfig(
        title: 'API',
        version: '1.0.0',
        contact: OpenApiContact(email: 'api@example.com'),
        license: OpenApiLicense(
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT',
        ),
      );

      final yaml = config.toYamlString();

      expect(yaml, contains('email: "api@example.com"'));
      expect(yaml, contains('url: "https://opensource.org/licenses/MIT"'));
    });
  });

  group('readPubspecInfo', () {
    test('reads the name, version, and description', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: my_api
version: 3.4.5
description: My test API.
dependencies:
''');

      final info = readPubspecInfo(temp);
      expect(info.name, 'my_api');
      expect(info.version, '3.4.5');
      expect(info.description, 'My test API.');
    });

    test('rejects a non-map pubspec', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(
        p.join(temp.path, 'pubspec.yaml'),
      ).writeAsStringSync('- not a map\n');

      expect(() => readPubspecInfo(temp), throwsA(_configError));
    });

    test('derives defaults from a minimal pubspec', () {
      final temp = Directory.systemTemp.createTempSync('axle_config_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
description: A minimal package.
''');

      final config = AxleConfig.fromPubspec(temp);

      expect(config.title, startsWith('Axle Config '));
      expect(config.version, '0.1.0');
      expect(config.description, 'A minimal package.');
    });
  });
}

final _configError = isA<AxleException>().having(
  (error) => error.exitCode,
  'exitCode',
  AxleExitCode.config,
);

void _expectAllConfigFailures(
  Map<String, String> cases, {
  bool createLib = false,
}) {
  for (final entry in cases.entries) {
    final temp = Directory.systemTemp.createTempSync('axle_config_');
    try {
      if (createLib) Directory(p.join(temp.path, 'lib')).createSync();
      File(
        p.join(temp.path, AxleConfig.fileName),
      ).writeAsStringSync(entry.value);
      expect(
        () => AxleConfig.load(temp),
        throwsA(_configError),
        reason: entry.key,
      );
    } finally {
      temp.deleteSync(recursive: true);
    }
  }
}
