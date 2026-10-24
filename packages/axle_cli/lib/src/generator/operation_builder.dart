/// Builds an OpenAPI document from annotated analyzer libraries.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:axle_core/axle_core.dart';

import '../config.dart';
import '../errors.dart';
import 'annotations.dart';
import 'schema_registry.dart';

/// Builds [OpenApiDocument] instances from resolved Dart libraries.
class OpenApiSpecBuilder {
  /// Creates a document builder.
  OpenApiSpecBuilder({required this.config, required this.registry});

  /// The project configuration.
  final AxleConfig config;

  /// The schema registry used for component schemas.
  final SchemaRegistry registry;

  /// Builds a document from [libraries].
  OpenApiDocument build(List<LibraryElement> libraries) {
    _preRegisterSchemas(libraries);

    final paths = <String, Map<String, OpenApiOperation>>{};
    final operationIds = <String, String>{};

    for (final library in libraries) {
      for (final function in library.topLevelFunctions) {
        for (final annotation in annotationsNamed(function, 'ApiRoute')) {
          final route = readApiRoute(annotation, function);
          if (route.ignore) continue;

          final path = normalizeOpenApiPath(route.path);
          final method = route.method.toLowerCase();
          final operation = _buildOperation(
            route: route,
            function: function,
            path: path,
            method: method,
            operationIds: operationIds,
          );

          final pathItem = paths.putIfAbsent(path, () => {});
          if (pathItem.containsKey(method)) {
            throw AxleException(
              'Duplicate route ${method.toUpperCase()} $path '
              '(from ${function.displayName}).',
              exitCode: AxleExitCode.data,
            );
          }
          pathItem[method] = operation;
        }
      }
    }

    final sortedPaths = paths.keys.toList()..sort();
    return OpenApiDocument(
      openApi: config.openApiVersion,
      info: OpenApiInfo(
        title: config.title,
        version: config.version,
        description: config.description,
        termsOfService: config.termsOfService,
        contact: config.contact,
        license: config.license,
      ),
      tags: config.tags,
      externalDocs: config.externalDocs,
      servers: config.servers,
      paths: {
        for (final path in sortedPaths) path: OpenApiPathItem(paths[path]!),
      },
      components: OpenApiComponents(
        schemas: registry.schemas,
        securitySchemes: {
          for (final name in config.securitySchemes.keys.toList()..sort())
            name: config.securitySchemes[name]!,
        },
      ),
      security: _defaultSecurity(),
    );
  }

  List<OpenApiSecurityRequirement> _defaultSecurity() {
    if (config.defaultSecurity.isEmpty) return const [];
    final schemes = <String, List<String>>{};
    for (final name in config.defaultSecurity) {
      final scheme = config.securitySchemes[name];
      if (scheme == null) {
        throw AxleException(
          '`security.default` references unknown scheme `$name`.',
          exitCode: AxleExitCode.config,
        );
      }
      schemes[name] = const [];
    }
    return [OpenApiSecurityRequirement(schemes)];
  }

  void _preRegisterSchemas(List<LibraryElement> libraries) {
    for (final library in libraries) {
      final classes = [...library.classes]
        ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      for (final element in classes) {
        final annotation = annotationNamed(element, 'ApiSchema');
        if (annotation == null) continue;
        final data = readApiSchema(annotation);
        if (data.ignore) continue;
        registry.registerClass(
          element,
          nameOverride: data.name,
          description: data.description,
        );
      }
    }
  }

  OpenApiOperation _buildOperation({
    required ApiRouteData route,
    required TopLevelFunctionElement function,
    required String path,
    required String method,
    required Map<String, String> operationIds,
  }) {
    final functionName = function.name ?? 'operation';
    final operationId = route.operationId ?? functionName;
    final existing = operationIds[operationId];
    if (existing != null) {
      throw AxleException(
        'Duplicate operationId `$operationId` for ${method.toUpperCase()} '
        '$path and $existing. Set a unique `operationId` on @ApiRoute.',
        exitCode: AxleExitCode.data,
      );
    }
    operationIds[operationId] = '${method.toUpperCase()} $path';

    return OpenApiOperation(
      operationId: operationId,
      summary: route.summary,
      description: route.description,
      tags: route.tags,
      deprecated: route.deprecated,
      parameters: _parameters(route, path, method),
      requestBody: _requestBody(route, method, path),
      responses: _responses(route, method, path),
      security: _security(route, method, path),
    );
  }

  List<OpenApiParameter> _parameters(
    ApiRouteData route,
    String path,
    String method,
  ) {
    final declaredPathParams = <String, ApiParameterData>{
      for (final parameter in route.pathParams)
        normalizeParameterName(parameter.name): parameter,
    };
    final placeholders = _pathParameterNames(path);
    final parameters = <OpenApiParameter>[];

    for (final name in placeholders) {
      final declared = declaredPathParams.remove(name);
      OpenApiSchema schema;
      String? description;
      Object? example;
      if (declared == null) {
        registry.warnings.add(
          'Path `${method.toUpperCase()} $path` has parameter `{$name}` '
          'without an @ApiPathParam. A string schema was used.',
        );
        schema = const OpenApiSchema.string();
      } else {
        schema = _withConstraints(
          registry.schemaForType(
            declared.type,
            context: '$method $path path parameter $name',
          ),
          declared,
        );
        description = declared.description;
        example = declared.example;
      }
      parameters.add(
        OpenApiParameter(
          name: name,
          location: OpenApiParameterLocation.path,
          required: true,
          schema: schema,
          description: description,
          example: example,
        ),
      );
    }

    if (declaredPathParams.isNotEmpty) {
      throw AxleException(
        'Path `${method.toUpperCase()} $path` declares unused path '
        'parameters: ${declaredPathParams.keys.join(', ')}.',
        exitCode: AxleExitCode.data,
      );
    }

    for (final parameter in route.queryParams) {
      var schema = _withConstraints(
        registry.schemaForType(
          parameter.type,
          context: '$method $path query parameter ${parameter.name}',
        ),
        parameter,
      );
      if (parameter.defaultValue != null) {
        schema = schema.withDefaultValue(parameter.defaultValue);
      }
      parameters.add(
        OpenApiParameter(
          name: parameter.name,
          location: OpenApiParameterLocation.query,
          required: parameter.required,
          schema: schema,
          description: parameter.description,
          example: parameter.example,
        ),
      );
    }

    for (final parameter in route.headerParams) {
      parameters.add(
        OpenApiParameter(
          name: parameter.name,
          location: OpenApiParameterLocation.header,
          required: parameter.required,
          schema: _withConstraints(
            registry.schemaForType(
              parameter.type,
              context: '$method $path header parameter ${parameter.name}',
            ),
            parameter,
          ),
          description: parameter.description,
          example: parameter.example,
        ),
      );
    }

    for (final parameter in route.cookieParams) {
      parameters.add(
        OpenApiParameter(
          name: parameter.name,
          location: OpenApiParameterLocation.cookie,
          required: parameter.required,
          schema: _withConstraints(
            registry.schemaForType(
              parameter.type,
              context: '$method $path cookie parameter ${parameter.name}',
            ),
            parameter,
          ),
          description: parameter.description,
          example: parameter.example,
        ),
      );
    }

    return parameters;
  }

  OpenApiSchema _withConstraints(
    OpenApiSchema schema,
    ApiParameterData parameter,
  ) {
    return schema.withConstraints(
      format: parameter.format,
      enumValues: parameter.enumValues,
      minimum: parameter.minimum,
      maximum: parameter.maximum,
      minLength: parameter.minLength,
      maxLength: parameter.maxLength,
      pattern: parameter.pattern,
    );
  }

  OpenApiRequestBody? _requestBody(
    ApiRouteData route,
    String method,
    String path,
  ) {
    final body = route.body;
    if (body == null) return null;
    if (body.contentTypes.isEmpty) {
      throw AxleException(
        '@ApiBody for ${method.toUpperCase()} $path must declare at least one '
        'content type.',
        exitCode: AxleExitCode.data,
      );
    }
    final schema = registry.schemaForType(
      body.type,
      context: '$method $path body',
    );
    return OpenApiRequestBody(
      description: body.description,
      required: body.required,
      content: {
        for (final contentType in body.contentTypes)
          contentType: OpenApiMediaType(schema: schema, example: body.example),
      },
    );
  }

  Map<String, OpenApiResponse> _responses(
    ApiRouteData route,
    String method,
    String path,
  ) {
    final responses = <String, OpenApiResponse>{};
    if (route.responses.isEmpty) {
      responses['200'] = const OpenApiResponse(description: 'OK');
    } else {
      for (final response in route.responses) {
        if (response.status < 100 || response.status > 599) {
          throw AxleException(
            'Invalid response status ${response.status} for '
            '${method.toUpperCase()} $path.',
            exitCode: AxleExitCode.data,
          );
        }
        final key = response.status.toString();
        if (responses.containsKey(key)) {
          throw AxleException(
            'Duplicate response status $key for ${method.toUpperCase()} $path.',
            exitCode: AxleExitCode.data,
          );
        }
        if (response.contentTypes.isEmpty) {
          throw AxleException(
            'Response $key for ${method.toUpperCase()} $path must declare at '
            'least one content type.',
            exitCode: AxleExitCode.data,
          );
        }
        var schema = response.type == null
            ? null
            : registry.schemaForType(
                response.type!,
                context: '$method $path response $key',
              );
        if (schema != null && response.nullable) schema = schema.asNullable();
        final headers = <String, OpenApiHeader>{};
        for (final header in response.headers) {
          if (header.name.trim().isEmpty) {
            throw AxleException(
              'Response $key for ${method.toUpperCase()} $path has an empty '
              'header name.',
              exitCode: AxleExitCode.data,
            );
          }
          headers[header.name] = OpenApiHeader(
            schema: registry.schemaForType(
              header.type,
              context: '$method $path response $key header ${header.name}',
            ),
            description: header.description,
            required: header.required,
            deprecated: header.deprecated,
          );
        }
        responses[key] = OpenApiResponse(
          description: response.description.isEmpty
              ? _statusDescription(response.status)
              : response.description,
          headers: headers,
          content: schema == null
              ? const {}
              : {
                  for (final contentType in response.contentTypes)
                    contentType: OpenApiMediaType(
                      schema: schema,
                      example: response.example,
                    ),
                },
        );
      }
    }

    final sortedKeys = responses.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return {for (final key in sortedKeys) key: responses[key]!};
  }

  List<OpenApiSecurityRequirement>? _security(
    ApiRouteData route,
    String method,
    String path,
  ) {
    final requirements = route.security;
    if (requirements == null) return null;
    final result = <OpenApiSecurityRequirement>[];
    for (final requirement in requirements) {
      final schemes = <String, List<String>>{};
      for (final name in requirement.schemes) {
        if (name.trim().isEmpty) {
          throw AxleException(
            '@ApiRoute ${method.toUpperCase()} $path has an empty security '
            'scheme name.',
            exitCode: AxleExitCode.data,
          );
        }
        if (!config.securitySchemes.containsKey(name)) {
          throw AxleException(
            '@ApiRoute ${method.toUpperCase()} $path references unknown '
            'security scheme `$name`. Define it under `security.schemes` in '
            'axle.yaml.',
            exitCode: AxleExitCode.data,
          );
        }
        schemes[name] = requirement.scopes[name] ?? const [];
      }
      if (schemes.isEmpty) {
        throw AxleException(
          '@ApiRoute ${method.toUpperCase()} $path has an empty security '
          'requirement. Use `security: []` to make the operation public.',
          exitCode: AxleExitCode.data,
        );
      }
      result.add(OpenApiSecurityRequirement(schemes));
    }
    return result;
  }
}

/// Converts a Relic or Shelf path to an OpenAPI path.
///
/// Relic placeholders (`:id`) and Shelf placeholders (`<id>`) become `{id}`.
String normalizeOpenApiPath(String path) {
  var result = path.trim();
  if (result.isEmpty) {
    throw AxleException(
      'Route paths must not be empty.',
      exitCode: AxleExitCode.data,
    );
  }
  if (!result.startsWith('/')) result = '/$result';
  result = result.replaceAllMapped(
    RegExp(r':([A-Za-z_][A-Za-z0-9_]*)'),
    (match) => '{${match[1]}}',
  );
  result = result.replaceAllMapped(
    RegExp(r'<([A-Za-z_][A-Za-z0-9_]*)(?:\|[^>]*)?>'),
    (match) => '{${match[1]}}',
  );
  if (result.contains('*')) {
    throw AxleException(
      'Wildcard route `$path` cannot be represented in OpenAPI. '
      'Add `ignore: true` to its @ApiRoute annotation.',
      exitCode: AxleExitCode.data,
    );
  }
  return result.replaceAll(RegExp(r'/{2,}'), '/');
}

/// Removes the syntax used around a parameter name in an annotation.
String normalizeParameterName(String name) {
  return name
      .trim()
      .replaceFirst(RegExp(r'^[:<{]'), '')
      .replaceFirst(RegExp(r'[>}]$'), '');
}

Set<String> _pathParameterNames(String path) {
  final names = <String>{};
  for (final match in RegExp(r'\{([^}]+)\}').allMatches(path)) {
    final name = match.group(1)?.trim();
    if (name == null || name.isEmpty) {
      throw AxleException(
        'Empty path parameter in `$path`.',
        exitCode: AxleExitCode.data,
      );
    }
    names.add(name);
  }
  return names;
}

String _statusDescription(int status) {
  return const {
        200: 'OK',
        201: 'Created',
        202: 'Accepted',
        204: 'No Content',
        400: 'Bad Request',
        401: 'Unauthorized',
        403: 'Forbidden',
        404: 'Not Found',
        409: 'Conflict',
        422: 'Unprocessable Entity',
        429: 'Too Many Requests',
        500: 'Internal Server Error',
        502: 'Bad Gateway',
        503: 'Service Unavailable',
      }[status] ??
      'Response';
}
