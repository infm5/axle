/// Builds an OpenAPI document from annotated analyzer libraries.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:axle_core/axle_core.dart';

import '../config.dart';
import '../errors.dart';
import 'annotations.dart';
import 'locations.dart';
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
    final errors = <AxleException>[];
    _preRegisterSchemas(libraries, errors);

    final paths = <String, Map<String, OpenApiOperation>>{};
    final operationIds = <String, String>{};

    for (final library in libraries) {
      for (final target in routeTargets(library)) {
        for (final annotation in annotationsNamed(target.element, 'ApiRoute')) {
          try {
            final route = readApiRoute(annotation, target.element);
            if (route.ignore) continue;

            final path = normalizeOpenApiPath(route.path);
            final method = route.method.toLowerCase();
            final operation = _buildOperation(
              route: route,
              target: target,
              path: path,
              method: method,
              operationIds: operationIds,
            );

            final pathItem = paths.putIfAbsent(path, () => {});
            if (pathItem.containsKey(method)) {
              throw AxleException(
                'Duplicate route ${method.toUpperCase()} $path '
                '(from ${elementLabel(target.element)}).',
                exitCode: AxleExitCode.data,
              );
            }
            pathItem[method] = operation;
          } on AxleException catch (error) {
            _collect(errors, error.withLocation(locationOf(target.element)));
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      throw errors.length == 1
          ? errors.single
          : AxleDiagnosticsException(errors);
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

  /// Adds [error] to [errors] unless the same diagnostic is already there.
  ///
  /// A broken DTO is reached again from every route that references it.
  void _collect(List<AxleException> errors, AxleException error) {
    if (errors.every((existing) => existing.formatted != error.formatted)) {
      errors.add(error);
    }
  }

  void _preRegisterSchemas(
    List<LibraryElement> libraries,
    List<AxleException> errors,
  ) {
    for (final library in libraries) {
      final classes = [...library.classes]
        ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      for (final element in classes) {
        final annotation = annotationNamed(element, 'ApiSchema');
        if (annotation == null) continue;
        final data = readApiSchema(annotation);
        if (data.ignore) continue;
        // Generic classes are registered per instantiation, where they are used.
        if (element.typeParameters.isNotEmpty) continue;
        try {
          registry.registerClass(
            element,
            nameOverride: data.name,
            description: data.description,
          );
        } on AxleException catch (error) {
          _collect(errors, error.withLocation(locationOf(element)));
        }
      }
    }
  }

  OpenApiOperation _buildOperation({
    required ApiRouteData route,
    required RouteTarget target,
    required String path,
    required String method,
    required Map<String, String> operationIds,
  }) {
    final operationId = route.operationId ?? target.defaultOperationId;
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
      var extras = const _ParameterExtras();
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
        extras = _extras(
          declared,
          OpenApiParameterLocation.path,
          '$method $path path parameter $name',
        );
      }
      parameters.add(
        OpenApiParameter(
          name: name,
          location: OpenApiParameterLocation.path,
          required: true,
          schema: schema,
          description: description,
          example: extras.examples.isEmpty ? example : null,
          examples: extras.examples,
          style: extras.style,
          explode: extras.explode,
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
      final extras = _extras(
        parameter,
        OpenApiParameterLocation.query,
        '$method $path query parameter ${parameter.name}',
      );
      parameters.add(
        OpenApiParameter(
          name: parameter.name,
          location: OpenApiParameterLocation.query,
          required: parameter.required,
          schema: schema,
          description: parameter.description,
          example: parameter.example,
          examples: extras.examples,
          style: extras.style,
          explode: extras.explode,
        ),
      );
    }

    for (final parameter in route.headerParams) {
      final extras = _extras(
        parameter,
        OpenApiParameterLocation.header,
        '$method $path header parameter ${parameter.name}',
      );
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
          examples: extras.examples,
          style: extras.style,
          explode: extras.explode,
        ),
      );
    }

    for (final parameter in route.cookieParams) {
      final extras = _extras(
        parameter,
        OpenApiParameterLocation.cookie,
        '$method $path cookie parameter ${parameter.name}',
      );
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
          examples: extras.examples,
          style: extras.style,
          explode: extras.explode,
        ),
      );
    }

    return parameters;
  }

  /// Validates and converts `style`, `explode` and `examples` of a parameter.
  _ParameterExtras _extras(
    ApiParameterData parameter,
    OpenApiParameterLocation location,
    String label,
  ) {
    final examples = _examples(parameter.example, parameter.examples, label);
    final style = parameter.style;
    if (style != null && !_allowedStyles[location]!.contains(style)) {
      throw AxleException(
        'Style `$style` is not valid for the $label. '
        '${location.name} parameters allow: '
        '${_allowedStyles[location]!.join(', ')}.',
        exitCode: AxleExitCode.data,
      );
    }
    final effectiveStyle = style ?? _defaultStyles[location]!;
    final explode = parameter.explode;
    return _ParameterExtras(
      examples: examples,
      style: style == null || style == _defaultStyles[location] ? null : style,
      explode: explode == null || explode == (effectiveStyle == 'form')
          ? null
          : explode,
    );
  }

  /// Converts named examples, rejecting a mix of `example` and `examples`.
  Map<String, OpenApiExample> _examples(
    Object? example,
    Map<String, ApiExampleData> examples,
    String label,
  ) {
    if (examples.isEmpty) return const {};
    if (example != null) {
      throw AxleException(
        'The $label sets both `example` and `examples`. Use only one.',
        exitCode: AxleExitCode.data,
      );
    }
    final result = <String, OpenApiExample>{};
    for (final entry in examples.entries) {
      if (entry.key.trim().isEmpty) {
        throw AxleException(
          'The $label has an example with an empty name.',
          exitCode: AxleExitCode.data,
        );
      }
      final data = entry.value;
      result[entry.key] = data.externalValue != null
          ? OpenApiExample.external(
              data.externalValue!,
              summary: data.summary,
              description: data.description,
            )
          : OpenApiExample(
              value: data.value,
              summary: data.summary,
              description: data.description,
            );
    }
    return result;
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
    final bodies = [?route.body, ...route.bodies];
    if (bodies.isEmpty) return null;

    final label = '${method.toUpperCase()} $path';
    final content = <String, OpenApiMediaType>{};
    for (final body in bodies) {
      if (body.contentTypes.isEmpty) {
        throw AxleException(
          '@ApiBody for $label must declare at least one content type.',
          exitCode: AxleExitCode.data,
        );
      }
      final schema = registry.schemaForType(
        body.type,
        context: '$method $path body',
      );
      final bodyExamples = _examples(
        body.example,
        body.examples,
        '$label request body',
      );
      for (final contentType in body.contentTypes) {
        if (content.containsKey(contentType)) {
          throw AxleException(
            'The request body of $label declares `$contentType` more than '
            'once. Each media type may appear in one @ApiBody only.',
            exitCode: AxleExitCode.data,
          );
        }
        content[contentType] = OpenApiMediaType(
          schema: _mediaSchema(schema, body.type, contentType),
          example: body.example,
          examples: bodyExamples,
        );
      }
    }
    return OpenApiRequestBody(
      description: bodies
          .map((body) => body.description)
          .firstWhere((text) => text != null, orElse: () => null),
      required: bodies.any((body) => body.required),
      content: content,
    );
  }

  /// The schema for [type] under [contentType].
  ///
  /// Bytes inside a JSON document are base64 text (`format: byte`). Any other
  /// media type carries the raw bytes, which OpenAPI calls `format: binary`.
  OpenApiSchema _mediaSchema(
    OpenApiSchema schema,
    DartType? type,
    String contentType,
  ) {
    if (type == null ||
        !registry.isByteData(type) ||
        contentType.toLowerCase().contains('json')) {
      return schema;
    }
    const binary = OpenApiSchema.string(format: 'binary');
    return schema.nullable ? binary.asNullable() : binary;
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
        final responseKey = response.key;
        if (responseKey == null
            ? (response.status < 100 || response.status > 599)
            : !_responseKeyPattern.hasMatch(responseKey)) {
          throw AxleException(
            'Invalid response status ${responseKey ?? response.status} for '
            '${method.toUpperCase()} $path.',
            exitCode: AxleExitCode.data,
          );
        }
        final key = responseKey ?? response.status.toString();
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
            example: header.example,
            required: header.required,
            deprecated: header.deprecated,
          );
        }
        final built = OpenApiResponse(
          description: response.description.isEmpty
              ? _statusDescription(response.status, responseKey)
              : response.description,
          headers: headers,
          content: schema == null
              ? const {}
              : {
                  for (final contentType in response.contentTypes)
                    contentType: OpenApiMediaType(
                      schema: _mediaSchema(schema, response.type, contentType),
                      example: response.example,
                      examples: _examples(
                        response.example,
                        response.examples,
                        'response $key of ${method.toUpperCase()} $path',
                      ),
                    ),
                },
        );
        responses[key] = _mergeResponse(
          responses[key],
          built,
          key,
          '${method.toUpperCase()} $path',
        );
      }
    }

    final sortedKeys = responses.keys.toList()
      ..sort((a, b) => _responseOrder(a).compareTo(_responseOrder(b)));
    return {for (final key in sortedKeys) key: responses[key]!};
  }

  /// Combines two responses that share a status, one media type each.
  ///
  /// A status may be declared several times when the responses carry different
  /// media types, for example JSON and CSV. A repeat that adds no new media type
  /// is a duplicate.
  OpenApiResponse _mergeResponse(
    OpenApiResponse? existing,
    OpenApiResponse added,
    String key,
    String label,
  ) {
    if (existing == null) return added;
    final overlaps =
        existing.content.isEmpty ||
        added.content.isEmpty ||
        added.content.keys.any(existing.content.containsKey);
    if (overlaps) {
      throw AxleException(
        'Duplicate response status $key for $label. Declare a status again '
        'only to add a different media type.',
        exitCode: AxleExitCode.data,
      );
    }
    return OpenApiResponse(
      description: existing.description,
      headers: {...added.headers, ...existing.headers},
      content: {...existing.content, ...added.content},
    );
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

final _responseKeyPattern = RegExp(r'^(default|[1-5]XX)$');

/// Exact codes first, then each range after the codes of its hundred, then
/// `default`.
double _responseOrder(String key) {
  if (key == 'default') return 1000;
  if (key.endsWith('XX')) return int.parse(key[0]) * 100 + 99.5;
  return int.parse(key).toDouble();
}

const _allowedStyles = {
  OpenApiParameterLocation.path: ['matrix', 'label', 'simple'],
  OpenApiParameterLocation.header: ['simple'],
  OpenApiParameterLocation.query: [
    'form',
    'spaceDelimited',
    'pipeDelimited',
    'deepObject',
  ],
  OpenApiParameterLocation.cookie: ['form'],
};

const _defaultStyles = {
  OpenApiParameterLocation.path: 'simple',
  OpenApiParameterLocation.header: 'simple',
  OpenApiParameterLocation.query: 'form',
  OpenApiParameterLocation.cookie: 'form',
};

class _ParameterExtras {
  const _ParameterExtras({this.examples = const {}, this.style, this.explode});

  final Map<String, OpenApiExample> examples;
  final String? style;
  final bool? explode;
}

String _statusDescription(int status, [String? key]) {
  if (key == 'default') return 'Unexpected error';
  if (key != null) {
    return const {
          '1': 'Informational',
          '2': 'Successful',
          '3': 'Redirection',
          '4': 'Client error',
          '5': 'Server error',
        }[key[0]] ??
        'Response';
  }
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

/// An element that can carry `@ApiRoute` annotations.
class RouteTarget {
  /// Creates a route target.
  const RouteTarget(this.element, this.defaultOperationId);

  /// The annotated function, method, or variable.
  final Element element;

  /// The `operationId` used when the annotation does not set one.
  final String defaultOperationId;
}

/// Returns every element of [library] that may declare an `@ApiRoute`.
///
/// That is top-level functions, top-level variables (for closures), and the
/// methods of classes and mixins. Methods default to `Class_method` so that
/// controllers with equally named methods do not collide.
Iterable<RouteTarget> routeTargets(LibraryElement library) sync* {
  for (final function in library.topLevelFunctions) {
    yield RouteTarget(function, function.name ?? 'operation');
  }
  for (final variable in library.topLevelVariables) {
    if (!variable.isOriginDeclaration) continue;
    yield RouteTarget(variable, variable.name ?? 'operation');
  }
  for (final type in [...library.classes, ...library.mixins]) {
    for (final method in type.methods) {
      yield RouteTarget(method, '${type.name}_${method.name}');
    }
  }
}
