/// Reads axle annotations from resolved analyzer elements.
library;

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../errors.dart';

const _axleCoreLibrary = 'package:axle_core/src/annotations.dart';

/// One path, query, or header parameter read from an annotation.
class ApiParameterData {
  /// Creates parameter data.
  const ApiParameterData({
    required this.name,
    required this.type,
    this.required = false,
    this.description,
    this.example,
    this.defaultValue,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
  });

  /// The parameter name.
  final String name;

  /// The Dart type of the parameter.
  final DartType type;

  /// Whether the parameter is required.
  final bool required;

  /// A description of the parameter.
  final String? description;

  /// An example value.
  final Object? example;

  /// The default value for query parameters.
  final Object? defaultValue;

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;
}

/// One request body read from an annotation.
class ApiBodyData {
  /// Creates body data.
  const ApiBodyData({
    required this.type,
    this.description,
    this.required = true,
    this.example,
    this.contentTypes = const ['application/json'],
  });

  /// The Dart type of the body.
  final DartType type;

  /// A description of the body.
  final String? description;

  /// Whether the body is required.
  final bool required;

  /// An example body.
  final Object? example;

  /// The media types accepted by the operation.
  final List<String> contentTypes;
}

/// One response header read from an annotation.
class ApiResponseHeaderData {
  /// Creates response header data.
  const ApiResponseHeaderData({
    required this.name,
    required this.type,
    this.description,
    this.example,
    this.required = false,
    this.deprecated = false,
  });

  /// The header name.
  final String name;

  /// The Dart type of the header value.
  final DartType type;

  /// A description of the header.
  final String? description;

  /// An example value.
  final Object? example;

  /// Whether the header is required.
  final bool required;

  /// Whether the header is deprecated.
  final bool deprecated;
}

/// One response read from an annotation.
class ApiResponseData {
  /// Creates response data.
  const ApiResponseData({
    required this.status,
    required this.description,
    this.type,
    this.nullable = false,
    this.example,
    this.headers = const [],
    this.contentTypes = const ['application/json'],
  });

  /// The HTTP status code.
  final int status;

  /// A description of the response.
  final String description;

  /// The Dart type of the response body.
  final DartType? type;

  /// Whether the response body may be null.
  final bool nullable;

  /// An example response body.
  final Object? example;

  /// Response headers.
  final List<ApiResponseHeaderData> headers;

  /// The media types produced by the response.
  final List<String> contentTypes;
}

/// One security requirement read from an annotation.
class ApiSecurityRequirementData {
  /// Creates security requirement data.
  const ApiSecurityRequirementData({
    required this.schemes,
    this.scopes = const {},
  });

  /// Scheme names that must all be satisfied.
  final List<String> schemes;

  /// OAuth2 scopes keyed by scheme name.
  final Map<String, List<String>> scopes;
}

/// One route read from an `@ApiRoute` annotation.
class ApiRouteData {
  /// Creates route data.
  const ApiRouteData({
    required this.method,
    required this.path,
    this.summary,
    this.description,
    this.operationId,
    this.tags = const [],
    this.deprecated = false,
    this.pathParams = const [],
    this.queryParams = const [],
    this.headerParams = const [],
    this.cookieParams = const [],
    this.body,
    this.responses = const [],
    this.security,
    this.ignore = false,
  });

  /// The lowercase HTTP method.
  final String method;

  /// The route path.
  final String path;

  /// A short summary.
  final String? summary;

  /// A longer description.
  final String? description;

  /// A stable operation id.
  final String? operationId;

  /// Documentation tags.
  final List<String> tags;

  /// Whether the operation is deprecated.
  final bool deprecated;

  /// The path parameters.
  final List<ApiParameterData> pathParams;

  /// The query parameters.
  final List<ApiParameterData> queryParams;

  /// The header parameters.
  final List<ApiParameterData> headerParams;

  /// The cookie parameters.
  final List<ApiParameterData> cookieParams;

  /// The request body.
  final ApiBodyData? body;

  /// The responses.
  final List<ApiResponseData> responses;

  /// Security requirements, or `null` to inherit the document default.
  final List<ApiSecurityRequirementData>? security;

  /// Whether the route should be skipped.
  final bool ignore;
}

/// One discriminator read from an `@ApiSchema` annotation.
class ApiDiscriminatorData {
  /// Creates discriminator data.
  const ApiDiscriminatorData(this.propertyName, {this.mapping = const {}});

  /// The property whose value selects the schema.
  final String propertyName;

  /// Optional values mapped to schema names.
  final Map<String, String> mapping;
}

/// One schema read from an `@ApiSchema` annotation.
class ApiSchemaData {
  /// Creates schema data.
  const ApiSchemaData({
    this.name,
    this.description,
    this.oneOf = const [],
    this.discriminator,
    this.ignore = false,
  });

  /// An optional schema name override.
  final String? name;

  /// An optional schema description.
  final String? description;

  /// Concrete types that satisfy this schema.
  final List<DartType> oneOf;

  /// The discriminator used with [oneOf].
  final ApiDiscriminatorData? discriminator;

  /// Whether auto-inclusion should be skipped.
  final bool ignore;
}

/// One property read from an `@ApiProperty` annotation.
class ApiPropertyData {
  /// Creates property data.
  const ApiPropertyData({
    this.name,
    this.description,
    this.example,
    this.required,
    this.format,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.ignore = false,
  });

  /// An optional JSON property name override.
  final String? name;

  /// An optional description.
  final String? description;

  /// An optional example value.
  final Object? example;

  /// Whether the property is required.
  final bool? required;

  /// The JSON Schema format.
  final String? format;

  /// The allowed values, when this is an enum.
  final List<Object?> enumValues;

  /// The inclusive minimum for numeric values.
  final num? minimum;

  /// The inclusive maximum for numeric values.
  final num? maximum;

  /// The minimum string length.
  final int? minLength;

  /// The maximum string length.
  final int? maxLength;

  /// A regular expression the value must match.
  final String? pattern;

  /// Whether the property should be skipped.
  final bool ignore;
}

/// The subset of `@JsonKey` that affects generated schemas.
class JsonKeyData {
  /// Creates JSON key data.
  const JsonKeyData({
    this.name,
    this.includeToJson = true,
    this.includeFromJson = true,
    this.defaultValue,
  });

  /// The serialized property name.
  final String? name;

  /// Whether the field is included when encoding.
  final bool includeToJson;

  /// Whether the field is included when decoding.
  final bool includeFromJson;

  /// The declared default value.
  final Object? defaultValue;
}

/// Returns every annotation of [name] on [element].
List<DartObject> annotationsNamed(Element element, String name) {
  final result = <DartObject>[];
  for (final annotation in element.metadata.annotations) {
    final annotationElement = annotation.element;
    final enclosing = annotationElement?.enclosingElement;
    if (enclosing is! ClassElement ||
        enclosing.name != name ||
        enclosing.library.uri.toString() != _axleCoreLibrary) {
      continue;
    }
    result.add(_computeAnnotation(annotation, element));
  }
  return result;
}

/// Returns the first annotation of [name] on [element], if any.
DartObject? annotationNamed(Element element, String name) {
  final all = annotationsNamed(element, name);
  return all.isEmpty ? null : all.first;
}

/// Whether [value] is an axle annotation with [name].
bool isAxleAnnotation(DartObject value, String name) {
  final element = value.type?.element;
  return element is ClassElement &&
      element.name == name &&
      element.library.uri.toString() == _axleCoreLibrary;
}

/// Reads an `@ApiRoute` annotation.
ApiRouteData readApiRoute(DartObject value, Element element) {
  final method = value.getField('method')?.variable?.name;
  if (method == null) {
    throw AxleException(
      '@ApiRoute on ${element.displayName} has no valid method.',
      exitCode: AxleExitCode.data,
    );
  }
  final path = stringField(value, 'path');
  if (path == null || path.trim().isEmpty) {
    throw AxleException(
      '@ApiRoute on ${element.displayName} has no path.',
      exitCode: AxleExitCode.data,
    );
  }

  final bodyValue = value.getField('body');
  final body = bodyValue == null || bodyValue.isNull
      ? null
      : ApiBodyData(
          type: _requiredType(bodyValue, 'type', element, 'body'),
          description: stringField(bodyValue, 'description'),
          required: boolField(bodyValue, 'required') ?? true,
          example: constValue(bodyValue.getField('example')),
          contentTypes: _stringList(bodyValue, 'contentTypes'),
        );

  final responses = <ApiResponseData>[];
  for (final responseValue in listField(value, 'responses')) {
    responses.add(
      ApiResponseData(
        status: intField(responseValue, 'status') ?? 200,
        description: stringField(responseValue, 'description') ?? '',
        type: typeField(responseValue, 'type'),
        nullable: boolField(responseValue, 'nullable') ?? false,
        example: constValue(responseValue.getField('example')),
        headers: [
          for (final headerValue in listField(responseValue, 'headers'))
            ApiResponseHeaderData(
              name: stringField(headerValue, 'name') ?? '',
              type: _requiredType(
                headerValue,
                'type',
                element,
                'response header',
              ),
              description: stringField(headerValue, 'description'),
              example: constValue(headerValue.getField('example')),
              required: boolField(headerValue, 'required') ?? false,
              deprecated: boolField(headerValue, 'deprecated') ?? false,
            ),
        ],
        contentTypes: _stringList(responseValue, 'contentTypes'),
      ),
    );
  }

  return ApiRouteData(
    method: method,
    path: path,
    summary: stringField(value, 'summary'),
    description: stringField(value, 'description'),
    operationId: stringField(value, 'operationId'),
    tags: [
      for (final tag in listField(value, 'tags')) tag.toStringValue() ?? '',
    ].where((tag) => tag.isNotEmpty).toList(),
    deprecated: boolField(value, 'deprecated') ?? false,
    pathParams: _readParameters(value, 'pathParams', required: true),
    queryParams: _readParameters(value, 'queryParams'),
    headerParams: _readParameters(value, 'headerParams'),
    cookieParams: _readParameters(value, 'cookieParams'),
    body: body,
    responses: responses,
    security: _readSecurity(value),
    ignore: boolField(value, 'ignore') ?? false,
  );
}

/// Reads an `@ApiSchema` annotation.
ApiSchemaData readApiSchema(DartObject value) {
  final discriminatorValue = value.getField('discriminator');
  return ApiSchemaData(
    name: stringField(value, 'name'),
    description: stringField(value, 'description'),
    oneOf: [
      for (final type in listField(value, 'oneOf'))
        if (type.toTypeValue() case final DartType type) type,
    ],
    discriminator: discriminatorValue == null || discriminatorValue.isNull
        ? null
        : ApiDiscriminatorData(
            stringField(discriminatorValue, 'propertyName') ?? '',
            mapping: _stringMapField(discriminatorValue, 'mapping'),
          ),
    ignore: boolField(value, 'ignore') ?? false,
  );
}

Map<String, String> _stringMapField(DartObject value, String field) {
  final map = value.getField(field)?.toMapValue();
  if (map == null) return const {};
  return {
    for (final entry in map.entries)
      if (entry.key?.toStringValue() case final String key)
        if (entry.value?.toStringValue() case final String value) key: value,
  };
}

/// Reads an `@ApiProperty` annotation on [element], if present.
ApiPropertyData? readApiProperty(Element element) {
  final value = annotationNamed(element, 'ApiProperty');
  if (value == null) return null;
  return ApiPropertyData(
    name: stringField(value, 'name'),
    description: stringField(value, 'description'),
    example: constValue(value.getField('example')),
    required: boolField(value, 'required'),
    format: stringField(value, 'format'),
    enumValues: _constList(value.getField('enumValues')),
    minimum: numField(value, 'minimum'),
    maximum: numField(value, 'maximum'),
    minLength: intField(value, 'minLength'),
    maxLength: intField(value, 'maxLength'),
    pattern: stringField(value, 'pattern'),
    ignore: boolField(value, 'ignore') ?? false,
  );
}

/// Reads a `@JsonKey` annotation on [element], if present.
JsonKeyData? readJsonKey(Element element) {
  for (final annotation in element.metadata.annotations) {
    final annotationElement = annotation.element;
    final enclosing = annotationElement?.enclosingElement;
    if (enclosing is! ClassElement ||
        enclosing.name != 'JsonKey' ||
        !enclosing.library.uri.toString().contains('json_annotation')) {
      continue;
    }
    final value = _computeAnnotation(annotation, element);
    return JsonKeyData(
      name: stringField(value, 'name'),
      includeToJson: boolField(value, 'includeToJson') ?? true,
      includeFromJson: boolField(value, 'includeFromJson') ?? true,
      defaultValue: constValue(value.getField('defaultValue')),
    );
  }
  return null;
}

/// Returns the field value as a string.
String? stringField(DartObject? value, String name) {
  return value?.getField(name)?.toStringValue();
}

/// Returns the field value as a boolean.
bool? boolField(DartObject? value, String name) {
  return value?.getField(name)?.toBoolValue();
}

/// Returns the field value as an integer.
int? intField(DartObject? value, String name) {
  return value?.getField(name)?.toIntValue();
}

/// Returns the field value as a number.
num? numField(DartObject? value, String name) {
  final field = value?.getField(name);
  return field?.toIntValue() ?? field?.toDoubleValue();
}

/// Returns the field value as a Dart type.
DartType? typeField(DartObject? value, String name) {
  return value?.getField(name)?.toTypeValue();
}

/// Returns the field value as a list of constant objects.
List<DartObject> listField(DartObject? value, String name) {
  return value?.getField(name)?.toListValue() ?? const [];
}

/// Converts a constant value into a JSON-compatible Dart value.
Object? constValue(DartObject? value) {
  if (value == null || value.isNull) return null;

  final string = value.toStringValue();
  if (string != null) return string;

  final boolean = value.toBoolValue();
  if (boolean != null) return boolean;

  final integer = value.toIntValue();
  if (integer != null) return integer;

  final doubleValue = value.toDoubleValue();
  if (doubleValue != null) return doubleValue;

  final symbol = value.toSymbolValue();
  if (symbol != null) return symbol;

  final list = value.toListValue();
  if (list != null) return [for (final item in list) constValue(item)];

  final set = value.toSetValue();
  if (set != null) return [for (final item in set) constValue(item)];

  final map = value.toMapValue();
  if (map != null) {
    return {
      for (final entry in map.entries)
        constValue(entry.key)?.toString() ?? '': constValue(entry.value),
    };
  }

  final variable = value.variable;
  if (variable != null) return variable.name;

  final typeValue = value.toTypeValue();
  if (typeValue != null) return typeValue.getDisplayString();

  return null;
}

/// Returns the annotation's documentation comment as plain text.
String? cleanDocComment(String? comment) {
  if (comment == null) return null;
  final lines = comment
      .split('\n')
      .map((line) => line.trim().replaceFirst(RegExp(r'^///+\s?'), ''))
      .where((line) => line.isNotEmpty);
  final text = lines.join(' ').trim();
  return text.isEmpty ? null : text;
}

List<ApiParameterData> _readParameters(
  DartObject value,
  String field, {
  bool required = false,
}) {
  return [
    for (final parameter in listField(value, field))
      ApiParameterData(
        name: stringField(parameter, 'name') ?? '',
        type: _requiredType(parameter, 'type', null, field),
        required: required || (boolField(parameter, 'required') ?? false),
        description: stringField(parameter, 'description'),
        example: constValue(parameter.getField('example')),
        defaultValue: constValue(parameter.getField('defaultValue')),
        format: stringField(parameter, 'format'),
        enumValues: _constList(parameter.getField('enumValues')),
        minimum: numField(parameter, 'minimum'),
        maximum: numField(parameter, 'maximum'),
        minLength: intField(parameter, 'minLength'),
        maxLength: intField(parameter, 'maxLength'),
        pattern: stringField(parameter, 'pattern'),
      ),
  ];
}

List<String> _stringList(DartObject value, String field) {
  final raw = value.getField(field);
  if (raw == null || raw.isNull) return const ['application/json'];
  final list = raw.toListValue();
  if (list == null) return const ['application/json'];
  return [
    for (final item in list)
      if (item.toStringValue() case final String item) item,
  ];
}

List<Object?> _constList(DartObject? value) {
  final list = value?.toListValue();
  if (list == null) return const [];
  return [for (final item in list) constValue(item)];
}

List<ApiSecurityRequirementData>? _readSecurity(DartObject value) {
  final raw = value.getField('security');
  if (raw == null || raw.isNull) return null;
  return [
    for (final requirement in listField(value, 'security'))
      ApiSecurityRequirementData(
        schemes: [
          for (final scheme in listField(requirement, 'schemes'))
            if (scheme.toStringValue() case final String name) name,
        ],
        scopes: _readScopes(requirement),
      ),
  ];
}

Map<String, List<String>> _readScopes(DartObject requirement) {
  final raw = requirement.getField('scopes')?.toMapValue();
  if (raw == null) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.key?.toStringValue() case final String name)
        name: [
          for (final scope
              in entry.value?.toListValue() ?? const <DartObject>[])
            if (scope.toStringValue() case final String value) value,
        ],
  };
}

DartType _requiredType(
  DartObject value,
  String field,
  Element? owner,
  String context,
) {
  final type = typeField(value, field);
  if (type == null) {
    final ownerName = owner == null ? '' : ' on ${owner.displayName}';
    throw AxleException(
      'Missing `$field` type in $context$ownerName.',
      exitCode: AxleExitCode.data,
    );
  }
  return type;
}

DartObject _computeAnnotation(ElementAnnotation annotation, Element element) {
  final errors = annotation.constantEvaluationErrors;
  if (errors != null && errors.isNotEmpty) {
    final details = errors.map((error) => error.message).join('; ');
    throw AxleException(
      'Could not evaluate an annotation on ${element.displayName}: $details',
      exitCode: AxleExitCode.data,
    );
  }
  final value = annotation.computeConstantValue();
  if (value == null) {
    throw AxleException(
      'Could not evaluate an annotation on ${element.displayName}.',
      exitCode: AxleExitCode.data,
    );
  }
  return value;
}
