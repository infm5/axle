/// Reads and writes `axle.yaml`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:axle_core/axle_core.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'errors.dart';

/// The project configuration stored in `axle.yaml`.
///
/// The YAML file is the single source of truth for global API identity and
/// generator settings. Route and schema details belong in Dart annotations.
class AxleConfig {
  /// Creates a configuration.
  const AxleConfig({
    this.openApiVersion = '3.1.0',
    required this.title,
    required this.version,
    this.description,
    this.termsOfService,
    this.contact,
    this.license,
    this.tags = const [],
    this.externalDocs,
    this.servers = const [],
    this.securitySchemes = const {},
    this.defaultSecurity = const [],
    this.scan = const ['lib'],
    this.jsonOutput = 'build/openapi.json',
    this.swaggerUiOutput = 'assets/swagger-ui',
    this.dartOutput = 'lib/src/generated/openapi.g.dart',
  });

  /// The name of the configuration file.
  static const fileName = 'axle.yaml';

  /// The OpenAPI version written to the document.
  final String openApiVersion;

  /// The API title.
  final String title;

  /// The API version.
  final String version;

  /// A description of the API.
  final String? description;

  /// A URL to the API's terms of service.
  final String? termsOfService;

  /// Contact information for the API.
  final OpenApiContact? contact;

  /// License information for the API.
  final OpenApiLicense? license;

  /// Global tag metadata.
  final List<OpenApiTag> tags;

  /// Link to external API documentation.
  final OpenApiExternalDocs? externalDocs;

  /// Optional deployment server URLs.
  final List<OpenApiServer> servers;

  /// Security schemes available to annotated routes.
  final Map<String, OpenApiSecurityScheme> securitySchemes;

  /// Scheme names applied to every operation by default.
  final List<String> defaultSecurity;

  /// The directories or files scanned for annotations.
  final List<String> scan;

  /// The path of the generated JSON document, relative to the project root.
  final String jsonOutput;

  /// The directory containing generated Swagger UI assets.
  final String swaggerUiOutput;

  /// The path of the generated Dart constant, relative to the project root.
  final String dartOutput;

  /// Loads `axle.yaml` from [projectRoot].
  ///
  /// Throws an [AxleException] with [AxleExitCode.config] when the file is
  /// missing, malformed, contains unknown keys, or references paths outside the
  /// project.
  static AxleConfig load(
    Directory projectRoot, {
    String configFileName = fileName,
  }) {
    final root = projectRoot.absolute;
    final configPath = p.isAbsolute(configFileName)
        ? configFileName
        : p.join(root.path, configFileName);
    final file = File(configPath);
    if (!file.existsSync()) {
      throw AxleException(
        'No $configFileName found in ${root.path}. '
        'Run `axle init` or `dart run axle_cli:axle init` first.',
        exitCode: AxleExitCode.config,
      );
    }

    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      throw AxleException(
        '$configFileName must contain a YAML map.',
        exitCode: AxleExitCode.config,
      );
    }
    _rejectUnknownKeys(document, const {
      'openapi',
      'info',
      'tags',
      'externalDocs',
      'servers',
      'security',
      'generate',
    }, configFileName);

    final info = _asMap(document['info'], 'info');
    _rejectUnknownKeys(info, const {
      'title',
      'version',
      'description',
      'termsOfService',
      'contact',
      'license',
    }, 'info');

    final openApiVersion =
        _optionalString(document['openapi'], 'openapi') ?? '3.1.0';
    if (!openApiVersion.startsWith('3.1.')) {
      throw AxleException(
        'Only OpenAPI 3.1 documents are supported, but `openapi` is '
        '`$openApiVersion`.',
        exitCode: AxleExitCode.config,
      );
    }

    final contact = _readContact(info['contact']);
    final license = _readLicense(info['license']);
    final tags = _readTags(document['tags']);
    final externalDocs = _readExternalDocs(document['externalDocs']);
    final servers = _readServers(document['servers']);
    final security = _readSecurity(document['security']);

    final generate = _asMap(document['generate'], 'generate');
    _rejectUnknownKeys(generate, const {'scan', 'output'}, 'generate');

    final scan = _requiredStringList(generate['scan'], 'generate.scan');
    for (final directory in scan) {
      _validateScanPath(root, directory);
    }

    final output = _asMap(generate['output'], 'generate.output');
    _rejectUnknownKeys(output, const {'json', 'ui', 'dart'}, 'generate.output');
    final jsonOutput = _requiredString(output['json'], 'generate.output.json');
    final swaggerUiOutput = output['ui'] == null
        ? 'assets/swagger-ui'
        : _requiredString(output['ui'], 'generate.output.ui');
    final dartOutput = _requiredString(output['dart'], 'generate.output.dart');
    _validateOutputPath(root, jsonOutput, 'generate.output.json');
    _validateOutputPath(root, swaggerUiOutput, 'generate.output.ui');
    _validateOutputPath(root, dartOutput, 'generate.output.dart');
    final outputPaths = {
      p.normalize(jsonOutput),
      p.normalize(swaggerUiOutput),
      p.normalize(dartOutput),
    };
    if (outputPaths.length != 3) {
      throw AxleException(
        'Generated JSON, UI, and Dart outputs must point to different paths.',
        exitCode: AxleExitCode.config,
      );
    }

    return AxleConfig(
      openApiVersion: openApiVersion,
      title: _requiredString(info['title'], 'info.title'),
      version: _requiredString(info['version'], 'info.version'),
      description: _optionalString(info['description'], 'info.description'),
      termsOfService: _optionalString(
        info['termsOfService'],
        'info.termsOfService',
      ),
      contact: contact,
      license: license,
      tags: tags,
      externalDocs: externalDocs,
      servers: servers,
      securitySchemes: security.schemes,
      defaultSecurity: security.defaultSecurity,
      scan: scan,
      jsonOutput: jsonOutput,
      swaggerUiOutput: swaggerUiOutput,
      dartOutput: dartOutput,
    );
  }

  /// Builds a configuration from the project's `pubspec.yaml`.
  ///
  /// This is only used by `axle init` to seed `axle.yaml`. `axle gen` never
  /// reads `pubspec.yaml`.
  factory AxleConfig.fromPubspec(Directory projectRoot) {
    final pubspec = _readPubspec(projectRoot);
    return AxleConfig(
      title: _humanize(pubspec.name),
      version: pubspec.version ?? '0.1.0',
      description: pubspec.description,
    );
  }

  /// Serializes the configuration to a YAML document.
  String toYamlString() {
    final buffer = StringBuffer()
      ..writeln('openapi: ${_yamlString(openApiVersion)}')
      ..writeln('info:')
      ..writeln('  title: ${_yamlString(title)}')
      ..writeln('  version: ${_yamlString(version)}');

    if (description != null) {
      buffer.writeln('  description: ${_yamlString(description!)}');
    }
    if (termsOfService != null) {
      buffer.writeln('  termsOfService: ${_yamlString(termsOfService!)}');
    }
    if (contact != null) {
      buffer.writeln('  contact:');
      if (contact!.name != null) {
        buffer.writeln('    name: ${_yamlString(contact!.name!)}');
      }
      if (contact!.url != null) {
        buffer.writeln('    url: ${_yamlString(contact!.url!)}');
      }
      if (contact!.email != null) {
        buffer.writeln('    email: ${_yamlString(contact!.email!)}');
      }
    }
    if (license != null) {
      buffer.writeln('  license:');
      buffer.writeln('    name: ${_yamlString(license!.name)}');
      if (license!.identifier != null) {
        buffer.writeln('    identifier: ${_yamlString(license!.identifier!)}');
      }
      if (license!.url != null) {
        buffer.writeln('    url: ${_yamlString(license!.url!)}');
      }
    }

    if (tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('  - name: ${_yamlString(tag.name)}');
        if (tag.description != null) {
          buffer.writeln('    description: ${_yamlString(tag.description!)}');
        }
        if (tag.externalDocs != null) {
          buffer.writeln('    externalDocs:');
          buffer.writeln('      url: ${_yamlString(tag.externalDocs!.url)}');
          if (tag.externalDocs!.description != null) {
            buffer.writeln(
              '      description: '
              '${_yamlString(tag.externalDocs!.description!)}',
            );
          }
        }
      }
    }
    if (externalDocs != null) {
      buffer.writeln('externalDocs:');
      buffer.writeln('  url: ${_yamlString(externalDocs!.url)}');
      if (externalDocs!.description != null) {
        buffer.writeln(
          '  description: ${_yamlString(externalDocs!.description!)}',
        );
      }
    }
    if (servers.isNotEmpty) {
      buffer.writeln('servers:');
      for (final server in servers) {
        buffer.writeln('  - url: ${_yamlString(server.url)}');
        if (server.description != null) {
          buffer.writeln(
            '    description: ${_yamlString(server.description!)}',
          );
        }
      }
    }
    if (securitySchemes.isNotEmpty || defaultSecurity.isNotEmpty) {
      buffer.writeln('security:');
      if (securitySchemes.isNotEmpty) {
        buffer.writeln('  schemes:');
        for (final name in securitySchemes.keys.toList()..sort()) {
          buffer.writeln('    ${_yamlString(name)}:');
          _writeSecurityScheme(buffer, securitySchemes[name]!);
        }
      }
      if (defaultSecurity.isNotEmpty) {
        buffer.writeln('  default:');
        for (final name in defaultSecurity) {
          buffer.writeln('    - ${_yamlString(name)}');
        }
      }
    }

    buffer.writeln('generate:');
    buffer.writeln('  scan:');
    for (final directory in scan) {
      buffer.writeln('    - ${_yamlString(directory)}');
    }
    buffer
      ..writeln('  output:')
      ..writeln('    json: ${_yamlString(jsonOutput)}')
      ..writeln('    ui: ${_yamlString(swaggerUiOutput)}')
      ..writeln('    dart: ${_yamlString(dartOutput)}');

    return buffer.toString();
  }
}

class _PubspecInfo {
  const _PubspecInfo({
    required this.name,
    required this.version,
    required this.description,
  });

  final String name;
  final String? version;
  final String? description;
}

/// Information read from a project's `pubspec.yaml`.
class PubspecInfo {
  /// Creates pubspec information.
  const PubspecInfo({
    required this.name,
    required this.version,
    required this.description,
  });

  /// The package name.
  final String name;

  /// The package version, when declared.
  final String? version;

  /// The package description, when declared.
  final String? description;
}

/// Reads package information from `pubspec.yaml`.
PubspecInfo readPubspecInfo(Directory projectRoot) {
  final info = _readPubspec(projectRoot);
  return PubspecInfo(
    name: info.name,
    version: info.version,
    description: info.description,
  );
}

_PubspecInfo _readPubspec(Directory projectRoot) {
  final file = File(p.join(projectRoot.absolute.path, 'pubspec.yaml'));
  if (!file.existsSync()) {
    throw AxleException(
      'No pubspec.yaml found in ${projectRoot.absolute.path}. '
      'Run this command from a Dart package root.',
      exitCode: AxleExitCode.config,
    );
  }
  final document = loadYaml(file.readAsStringSync());
  if (document is! YamlMap) {
    throw AxleException(
      'pubspec.yaml must contain a YAML map.',
      exitCode: AxleExitCode.config,
    );
  }
  return _PubspecInfo(
    name:
        _optionalString(document['name'], 'name') ??
        p.basename(projectRoot.absolute.path),
    version: _optionalString(document['version'], 'version'),
    description: _optionalString(document['description'], 'description'),
  );
}

YamlMap _asMap(Object? value, String name) {
  if (value is YamlMap) return value;
  throw AxleException(
    '`$name` must be a YAML map.',
    exitCode: AxleExitCode.config,
  );
}

String _requiredString(Object? value, String name) {
  final result = _optionalString(value, name);
  if (result == null || result.trim().isEmpty) {
    throw AxleException(
      '`$name` is required and must be a non-empty string.',
      exitCode: AxleExitCode.config,
    );
  }
  return result;
}

String? _optionalString(Object? value, String name) {
  if (value == null) return null;
  if (value is String) return value;
  throw AxleException(
    '`$name` must be a string.',
    exitCode: AxleExitCode.config,
  );
}

List<String> _requiredStringList(Object? value, String name) {
  if (value is! YamlList || value.isEmpty) {
    throw AxleException(
      '`$name` must be a non-empty list of paths.',
      exitCode: AxleExitCode.config,
    );
  }
  final result = <String>[];
  for (final entry in value) {
    if (entry is! String || entry.trim().isEmpty) {
      throw AxleException(
        'Each entry in `$name` must be a non-empty path string.',
        exitCode: AxleExitCode.config,
      );
    }
    result.add(entry);
  }
  return result;
}

OpenApiContact? _readContact(Object? value) {
  if (value == null) return null;
  final map = _asMap(value, 'info.contact');
  _rejectUnknownKeys(map, const {'name', 'url', 'email'}, 'info.contact');
  final contact = OpenApiContact(
    name: _optionalString(map['name'], 'info.contact.name'),
    url: _optionalString(map['url'], 'info.contact.url'),
    email: _optionalString(map['email'], 'info.contact.email'),
  );
  if (contact.name == null && contact.url == null && contact.email == null) {
    throw AxleException(
      '`info.contact` must contain at least one of `name`, `url`, or `email`.',
      exitCode: AxleExitCode.config,
    );
  }
  return contact;
}

List<OpenApiServer> _readServers(Object? value) {
  if (value == null) return const [];
  if (value is! YamlList) {
    throw AxleException(
      '`servers` must be a list of server maps.',
      exitCode: AxleExitCode.config,
    );
  }
  final servers = <OpenApiServer>[];
  final urls = <String>{};
  for (final entry in value) {
    final map = _asMap(entry, 'servers[]');
    _rejectUnknownKeys(map, const {'url', 'description'}, 'servers[]');
    final url = _requiredString(map['url'], 'servers[].url');
    if (!urls.add(url)) {
      throw AxleException(
        'Duplicate server URL `$url`.',
        exitCode: AxleExitCode.config,
      );
    }
    servers.add(
      OpenApiServer(
        url: url,
        description: _optionalString(
          map['description'],
          'servers[].description',
        ),
      ),
    );
  }
  return servers;
}

List<OpenApiTag> _readTags(Object? value) {
  if (value == null) return const [];
  if (value is! YamlList) {
    throw AxleException(
      '`tags` must be a list of tag maps.',
      exitCode: AxleExitCode.config,
    );
  }
  final tags = <OpenApiTag>[];
  final names = <String>{};
  for (final entry in value) {
    final map = _asMap(entry, 'tags[]');
    _rejectUnknownKeys(map, const {
      'name',
      'description',
      'externalDocs',
    }, 'tags[]');
    final name = _requiredString(map['name'], 'tags[].name');
    if (!names.add(name)) {
      throw AxleException(
        'Duplicate tag `$name`.',
        exitCode: AxleExitCode.config,
      );
    }
    tags.add(
      OpenApiTag(
        name: name,
        description: _optionalString(map['description'], 'tags[].description'),
        externalDocs: _readExternalDocs(map['externalDocs']),
      ),
    );
  }
  return tags;
}

OpenApiExternalDocs? _readExternalDocs(Object? value) {
  if (value == null) return null;
  final map = _asMap(value, 'externalDocs');
  _rejectUnknownKeys(map, const {'url', 'description'}, 'externalDocs');
  return OpenApiExternalDocs(
    url: _requiredString(map['url'], 'externalDocs.url'),
    description: _optionalString(
      map['description'],
      'externalDocs.description',
    ),
  );
}

OpenApiLicense? _readLicense(Object? value) {
  if (value == null) return null;
  final map = _asMap(value, 'info.license');
  _rejectUnknownKeys(map, const {'name', 'identifier', 'url'}, 'info.license');
  return OpenApiLicense(
    name: _requiredString(map['name'], 'info.license.name'),
    identifier: _optionalString(map['identifier'], 'info.license.identifier'),
    url: _optionalString(map['url'], 'info.license.url'),
  );
}

class _SecurityConfig {
  const _SecurityConfig({
    this.schemes = const {},
    this.defaultSecurity = const [],
  });

  final Map<String, OpenApiSecurityScheme> schemes;
  final List<String> defaultSecurity;
}

_SecurityConfig _readSecurity(Object? value) {
  if (value == null) return const _SecurityConfig();
  final map = _asMap(value, 'security');
  _rejectUnknownKeys(map, const {'schemes', 'default'}, 'security');

  final schemes = <String, OpenApiSecurityScheme>{};
  if (map['schemes'] != null) {
    final schemesMap = _asMap(map['schemes'], 'security.schemes');
    for (final entry in schemesMap.entries) {
      final name = entry.key;
      if (name is! String || name.trim().isEmpty) {
        throw AxleException(
          '`security.schemes` keys must be non-empty strings.',
          exitCode: AxleExitCode.config,
        );
      }
      schemes[name] = _readSecurityScheme(
        entry.value,
        'security.schemes.$name',
      );
    }
  }

  final defaultSecurity = _optionalStringList(
    map['default'],
    'security.default',
  );
  for (final name in defaultSecurity) {
    if (!schemes.containsKey(name)) {
      throw AxleException(
        '`security.default` references unknown scheme `$name`.',
        exitCode: AxleExitCode.config,
      );
    }
  }
  return _SecurityConfig(schemes: schemes, defaultSecurity: defaultSecurity);
}

OpenApiSecurityScheme _readSecurityScheme(Object? value, String path) {
  final map = _asMap(value, path);
  final type = _requiredString(map['type'], '$path.type');
  switch (type) {
    case 'http':
      _rejectUnknownKeys(map, const {
        'type',
        'description',
        'scheme',
        'bearerFormat',
      }, path);
      return OpenApiSecurityScheme(
        type: type,
        description: _optionalString(map['description'], '$path.description'),
        scheme: _requiredString(map['scheme'], '$path.scheme'),
        bearerFormat: _optionalString(
          map['bearerFormat'],
          '$path.bearerFormat',
        ),
      );
    case 'apiKey':
      _rejectUnknownKeys(map, const {
        'type',
        'description',
        'name',
        'in',
      }, path);
      final location = _requiredString(map['in'], '$path.in');
      if (!const {'header', 'query', 'cookie'}.contains(location)) {
        throw AxleException(
          '`$path.in` must be `header`, `query`, or `cookie`.',
          exitCode: AxleExitCode.config,
        );
      }
      return OpenApiSecurityScheme(
        type: type,
        description: _optionalString(map['description'], '$path.description'),
        name: _requiredString(map['name'], '$path.name'),
        location: location,
      );
    case 'oauth2':
      _rejectUnknownKeys(map, const {'type', 'description', 'flows'}, path);
      return OpenApiSecurityScheme(
        type: type,
        description: _optionalString(map['description'], '$path.description'),
        flows: _readOAuthFlows(map['flows'], '$path.flows'),
      );
    case 'openIdConnect':
      _rejectUnknownKeys(map, const {
        'type',
        'description',
        'openIdConnectUrl',
      }, path);
      return OpenApiSecurityScheme(
        type: type,
        description: _optionalString(map['description'], '$path.description'),
        openIdConnectUrl: _requiredString(
          map['openIdConnectUrl'],
          '$path.openIdConnectUrl',
        ),
      );
    default:
      throw AxleException(
        '`$path.type` must be `http`, `apiKey`, `oauth2`, or '
        '`openIdConnect`, but was `$type`.',
        exitCode: AxleExitCode.config,
      );
  }
}

OpenApiOAuthFlows _readOAuthFlows(Object? value, String path) {
  final map = _asMap(value, path);
  _rejectUnknownKeys(map, const {
    'implicit',
    'password',
    'clientCredentials',
    'authorizationCode',
  }, path);
  final implicit = map['implicit'] == null
      ? null
      : _readOAuthFlow(map['implicit'], '$path.implicit');
  final password = map['password'] == null
      ? null
      : _readOAuthFlow(map['password'], '$path.password');
  final clientCredentials = map['clientCredentials'] == null
      ? null
      : _readOAuthFlow(map['clientCredentials'], '$path.clientCredentials');
  final authorizationCode = map['authorizationCode'] == null
      ? null
      : _readOAuthFlow(map['authorizationCode'], '$path.authorizationCode');
  if (implicit == null &&
      password == null &&
      clientCredentials == null &&
      authorizationCode == null) {
    throw AxleException(
      '`$path` must define at least one OAuth2 flow.',
      exitCode: AxleExitCode.config,
    );
  }
  if (implicit != null && implicit.authorizationUrl == null) {
    throw AxleException(
      '`$path.implicit.authorizationUrl` is required.',
      exitCode: AxleExitCode.config,
    );
  }
  if (password != null && password.tokenUrl == null) {
    throw AxleException(
      '`$path.password.tokenUrl` is required.',
      exitCode: AxleExitCode.config,
    );
  }
  if (clientCredentials != null && clientCredentials.tokenUrl == null) {
    throw AxleException(
      '`$path.clientCredentials.tokenUrl` is required.',
      exitCode: AxleExitCode.config,
    );
  }
  if (authorizationCode != null &&
      (authorizationCode.authorizationUrl == null ||
          authorizationCode.tokenUrl == null)) {
    throw AxleException(
      '`$path.authorizationCode` requires both `authorizationUrl` and '
      '`tokenUrl`.',
      exitCode: AxleExitCode.config,
    );
  }
  return OpenApiOAuthFlows(
    implicit: implicit,
    password: password,
    clientCredentials: clientCredentials,
    authorizationCode: authorizationCode,
  );
}

OpenApiOAuthFlow _readOAuthFlow(Object? value, String path) {
  final map = _asMap(value, path);
  _rejectUnknownKeys(map, const {
    'authorizationUrl',
    'tokenUrl',
    'refreshUrl',
    'scopes',
  }, path);
  return OpenApiOAuthFlow(
    authorizationUrl: _optionalString(
      map['authorizationUrl'],
      '$path.authorizationUrl',
    ),
    tokenUrl: _optionalString(map['tokenUrl'], '$path.tokenUrl'),
    refreshUrl: _optionalString(map['refreshUrl'], '$path.refreshUrl'),
    scopes: map['scopes'] == null
        ? const {}
        : _stringMap(map['scopes'], '$path.scopes'),
  );
}

Map<String, String> _stringMap(Object? value, String path) {
  final map = _asMap(value, path);
  final result = <String, String>{};
  for (final entry in map.entries) {
    if (entry.key is! String || entry.value is! String) {
      throw AxleException(
        '`$path` must contain string keys and values.',
        exitCode: AxleExitCode.config,
      );
    }
    result[entry.key as String] = entry.value as String;
  }
  return result;
}

List<String> _optionalStringList(Object? value, String name) {
  if (value == null) return const [];
  if (value is! YamlList) {
    throw AxleException(
      '`$name` must be a list of strings.',
      exitCode: AxleExitCode.config,
    );
  }
  final result = <String>[];
  for (final entry in value) {
    if (entry is! String || entry.trim().isEmpty) {
      throw AxleException(
        'Each entry in `$name` must be a non-empty string.',
        exitCode: AxleExitCode.config,
      );
    }
    result.add(entry);
  }
  return result;
}

void _writeSecurityScheme(StringBuffer buffer, OpenApiSecurityScheme scheme) {
  buffer.writeln('      type: ${_yamlString(scheme.type)}');
  if (scheme.description != null) {
    buffer.writeln('      description: ${_yamlString(scheme.description!)}');
  }
  if (scheme.name != null) {
    buffer.writeln('      name: ${_yamlString(scheme.name!)}');
  }
  if (scheme.location != null) {
    buffer.writeln('      in: ${_yamlString(scheme.location!)}');
  }
  if (scheme.scheme != null) {
    buffer.writeln('      scheme: ${_yamlString(scheme.scheme!)}');
  }
  if (scheme.bearerFormat != null) {
    buffer.writeln('      bearerFormat: ${_yamlString(scheme.bearerFormat!)}');
  }
  if (scheme.openIdConnectUrl != null) {
    buffer.writeln(
      '      openIdConnectUrl: ${_yamlString(scheme.openIdConnectUrl!)}',
    );
  }
  final flows = scheme.flows;
  if (flows != null) {
    buffer.writeln('      flows:');
    if (flows.implicit != null) {
      _writeOAuthFlow(buffer, 'implicit', flows.implicit!);
    }
    if (flows.password != null) {
      _writeOAuthFlow(buffer, 'password', flows.password!);
    }
    if (flows.clientCredentials != null) {
      _writeOAuthFlow(buffer, 'clientCredentials', flows.clientCredentials!);
    }
    if (flows.authorizationCode != null) {
      _writeOAuthFlow(buffer, 'authorizationCode', flows.authorizationCode!);
    }
  }
}

void _writeOAuthFlow(StringBuffer buffer, String name, OpenApiOAuthFlow flow) {
  buffer.writeln('        $name:');
  if (flow.authorizationUrl != null) {
    buffer.writeln(
      '          authorizationUrl: ${_yamlString(flow.authorizationUrl!)}',
    );
  }
  if (flow.tokenUrl != null) {
    buffer.writeln('          tokenUrl: ${_yamlString(flow.tokenUrl!)}');
  }
  if (flow.refreshUrl != null) {
    buffer.writeln('          refreshUrl: ${_yamlString(flow.refreshUrl!)}');
  }
  if (flow.scopes.isEmpty) {
    buffer.writeln('          scopes: {}');
  } else {
    buffer.writeln('          scopes:');
    for (final entry in flow.scopes.entries) {
      buffer.writeln(
        '            ${_yamlString(entry.key)}: ${_yamlString(entry.value)}',
      );
    }
  }
}

void _rejectUnknownKeys(YamlMap map, Set<String> allowed, String path) {
  for (final key in map.keys) {
    if (key is! String || !allowed.contains(key)) {
      throw AxleException(
        'Unknown key `$key` in `$path`.',
        exitCode: AxleExitCode.config,
      );
    }
  }
}

void _validateScanPath(Directory root, String value) {
  final absolute = _absoluteWithinRoot(root, value, 'generate.scan');
  final type = FileSystemEntity.typeSync(absolute);
  if (type == FileSystemEntityType.notFound) {
    throw AxleException(
      'Scan path `$value` does not exist.',
      exitCode: AxleExitCode.config,
    );
  }
}

void _validateOutputPath(Directory root, String value, String name) {
  final absolute = _absoluteWithinRoot(root, value, name);
  if (p.equals(absolute, p.normalize(root.path))) {
    throw AxleException(
      '`$name` must point to a path inside the project, not the project root.',
      exitCode: AxleExitCode.config,
    );
  }
}

String _absoluteWithinRoot(Directory root, String value, String name) {
  final rootPath = p.normalize(root.absolute.path);
  final absolute = p.normalize(
    p.isAbsolute(value) ? value : p.join(rootPath, value),
  );
  if (!p.equals(absolute, rootPath) && !p.isWithin(rootPath, absolute)) {
    throw AxleException(
      '`$name` path `$value` must stay inside the project root.',
      exitCode: AxleExitCode.config,
    );
  }
  return absolute;
}

String _yamlString(String value) => jsonEncode(value);

String _humanize(String value) {
  final words = value
      .split(RegExp(r'[_\-\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1));
  return words.isEmpty ? value : words.join(' ');
}
