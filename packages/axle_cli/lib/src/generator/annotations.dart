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
}

/// One request body read from an annotation.
class ApiBodyData {
  /// Creates body data.
  const ApiBodyData({
    required this.type,
    this.description,
    this.required = true,
    this.example,
  });

  /// The Dart type of the body.
  final DartType type;

  /// A description of the body.
  final String? description;

  /// Whether the body is required.
  final bool required;

  /// An example body.
  final Object? example;
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
    this.body,
    this.responses = const [],
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

  /// The request body.
  final ApiBodyData? body;

  /// The responses.
  final List<ApiResponseData> responses;

  /// Whether the route should be skipped.
  final bool ignore;
}

/// One schema read from an `@ApiSchema` annotation.
class ApiSchemaData {
  /// Creates schema data.
  const ApiSchemaData({this.name, this.description, this.ignore = false});

  /// An optional schema name override.
  final String? name;

  /// An optional schema description.
  final String? description;

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
    body: body,
    responses: responses,
    ignore: boolField(value, 'ignore') ?? false,
  );
}

/// Reads an `@ApiSchema` annotation.
ApiSchemaData readApiSchema(DartObject value) {
  return ApiSchemaData(
    name: stringField(value, 'name'),
    description: stringField(value, 'description'),
    ignore: boolField(value, 'ignore') ?? false,
  );
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
      ),
  ];
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
