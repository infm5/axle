/// Reads axle annotations from resolved analyzer elements.
library;

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../errors.dart';
import 'build_options.dart';
import 'locations.dart' show elementLabel;

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
    this.examples = const {},
    this.style,
    this.explode,
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

  /// Named example values.
  final Map<String, ApiExampleData> examples;

  /// The serialization style (`form`, `simple`, ...), when set.
  final String? style;

  /// Whether array and object values produce one parameter per item, when set.
  final bool? explode;

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

/// One named example read from an annotation.
class ApiExampleData {
  /// Creates example data.
  const ApiExampleData({
    this.value,
    this.externalValue,
    this.summary,
    this.description,
  });

  /// The inline value.
  final Object? value;

  /// A URL of a document that holds the value.
  final String? externalValue;

  /// A short description.
  final String? summary;

  /// A longer description.
  final String? description;
}

/// One request body read from an annotation.
class ApiBodyData {
  /// Creates body data.
  const ApiBodyData({
    required this.type,
    this.description,
    this.required = true,
    this.example,
    this.examples = const {},
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

  /// Named example bodies.
  final Map<String, ApiExampleData> examples;

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
    this.key,
    this.type,
    this.nullable = false,
    this.example,
    this.examples = const {},
    this.headers = const [],
    this.contentTypes = const ['application/json'],
  });

  /// The HTTP status code, or the first status of a range.
  final int status;

  /// `default` or a range such as `4XX`; `null` for an exact status.
  final String? key;

  /// A description of the response.
  final String description;

  /// The Dart type of the response body.
  final DartType? type;

  /// Whether the response body may be null.
  final bool nullable;

  /// An example response body.
  final Object? example;

  /// Named example response bodies.
  final Map<String, ApiExampleData> examples;

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
    this.bodies = const [],
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

  /// More request bodies for other media types.
  final List<ApiBodyData> bodies;

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
    this.allOf = const [],
    this.anyOf = const [],
    this.discriminator,
    this.ignore = false,
  });

  /// An optional schema name override.
  final String? name;

  /// An optional schema description.
  final String? description;

  /// Concrete types that satisfy this schema.
  final List<DartType> oneOf;

  /// Types whose schemas this schema extends.
  final List<DartType> allOf;

  /// Concrete types of which at least one satisfies this schema.
  final List<DartType> anyOf;

  /// The discriminator used with [oneOf] or [anyOf].
  final ApiDiscriminatorData? discriminator;

  /// Whether auto-inclusion should be skipped.
  final bool ignore;
}

/// One property read from an `@ApiProperty` annotation.
class ApiPropertyData {
  /// Creates property data.
  const ApiPropertyData({
    this.name,
    this.type,
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

  /// The type that describes the property in JSON, overriding the field type.
  final DartType? type;

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
      '@ApiRoute on ${elementLabel(element)} has no valid method.',
      exitCode: AxleExitCode.data,
    );
  }
  final path = stringField(value, 'path');
  if (path == null || path.trim().isEmpty) {
    throw AxleException(
      '@ApiRoute on ${elementLabel(element)} has no path.',
      exitCode: AxleExitCode.data,
    );
  }

  final bodyValue = value.getField('body');
  final body = bodyValue == null || bodyValue.isNull
      ? null
      : _readBody(bodyValue, element);
  final bodies = [
    for (final bodyItem in listField(value, 'bodies'))
      _readBody(bodyItem, element),
  ];

  final responses = <ApiResponseData>[];
  for (final responseValue in listField(value, 'responses')) {
    responses.add(
      ApiResponseData(
        status: intField(responseValue, 'status') ?? 200,
        key: stringField(responseValue, 'key'),
        description: stringField(responseValue, 'description') ?? '',
        type: typeField(responseValue, 'type'),
        nullable: boolField(responseValue, 'nullable') ?? false,
        example: constValue(responseValue.getField('example')),
        examples: _readExamples(responseValue),
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
    bodies: bodies,
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
    oneOf: _typeList(value, 'oneOf'),
    allOf: _typeList(value, 'allOf'),
    anyOf: _typeList(value, 'anyOf'),
    discriminator: discriminatorValue == null || discriminatorValue.isNull
        ? null
        : ApiDiscriminatorData(
            stringField(discriminatorValue, 'propertyName') ?? '',
            mapping: _stringMapField(discriminatorValue, 'mapping'),
          ),
    ignore: boolField(value, 'ignore') ?? false,
  );
}

List<DartType> _typeList(DartObject value, String field) => [
  for (final type in listField(value, field))
    if (type.toTypeValue() case final DartType type) type,
];

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
    type: typeField(value, 'type'),
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
  final found = _jsonAnnotation(element, 'JsonKey');
  if (found == null) return null;
  final value = found.$2;
  return JsonKeyData(
    name: stringField(value, 'name'),
    includeToJson: boolField(value, 'includeToJson') ?? true,
    includeFromJson: boolField(value, 'includeFromJson') ?? true,
    defaultValue: constValue(value.getField('defaultValue')),
  );
}

/// Reads the `fieldRename` option of `@JsonSerializable` or `@JsonEnum`.
///
/// Returns the `FieldRename` constant name (`snake`, `kebab`, `pascal`,
/// `screamingSnake`), or `null` when the option is absent or `none`.
String? readFieldRename(Element element, {required bool forEnum}) {
  final found = _jsonAnnotation(
    element,
    forEnum ? 'JsonEnum' : 'JsonSerializable',
  );
  if (found == null) return null;
  final name = found.$2.getField('fieldRename')?.variable?.name;
  return name == null || name == 'none' ? null : name;
}

/// Reads the `@JsonValue` annotation on an enum constant, if present.
Object? readJsonValue(Element element) {
  final found = _jsonAnnotation(element, 'JsonValue');
  if (found == null) return null;
  return constValue(found.$2.getField('value'));
}

/// Applies a `json_serializable` `FieldRename` strategy to [name].
///
/// [rename] is a `FieldRename` constant name. Unknown strategies return
/// [name] unchanged.
String applyFieldRename(String name, String? rename) {
  String separated(String separator) => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '$separator${match.group(0)!.toLowerCase()}',
  );
  return switch (rename) {
    'snake' => separated('_'),
    'kebab' => separated('-'),
    'screamingSnake' => separated('_').toUpperCase(),
    'pascal' when name.isNotEmpty =>
      '${name[0].toUpperCase()}${name.substring(1)}',
    _ => name,
  };
}

(ElementAnnotation, DartObject)? _jsonAnnotation(
  Element element,
  String name,
) => _annotationFrom(element, name, 'json_annotation');

/// Finds the annotation class [name] declared in a library whose URI contains
/// [package].
(ElementAnnotation, DartObject)? _annotationFrom(
  Element element,
  String name,
  String package,
) {
  for (final annotation in element.metadata.annotations) {
    final enclosing = annotation.element?.enclosingElement;
    if (enclosing is! ClassElement ||
        enclosing.name != name ||
        !enclosing.library.uri.toString().contains(package)) {
      continue;
    }
    return (annotation, _computeAnnotation(annotation, element));
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
        examples: _readExamples(parameter),
        style: parameter.getField('style')?.variable?.name,
        explode: boolField(parameter, 'explode'),
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

Map<String, ApiExampleData> _readExamples(DartObject value) {
  final map = value.getField('examples')?.toMapValue();
  if (map == null) return const {};
  return {
    for (final entry in map.entries)
      if (entry.key?.toStringValue() case final String name)
        name: ApiExampleData(
          value: constValue(entry.value?.getField('value')),
          externalValue: stringField(entry.value, 'externalValue'),
          summary: stringField(entry.value, 'summary'),
          description: stringField(entry.value, 'description'),
        ),
  };
}

ApiBodyData _readBody(DartObject bodyValue, Element element) {
  return ApiBodyData(
    type: _requiredType(bodyValue, 'type', element, 'body'),
    description: stringField(bodyValue, 'description'),
    required: boolField(bodyValue, 'required') ?? true,
    example: constValue(bodyValue.getField('example')),
    examples: _readExamples(bodyValue),
    contentTypes: _stringList(bodyValue, 'contentTypes'),
  );
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
      'Could not evaluate an annotation on ${elementLabel(element)}: $details',
      exitCode: AxleExitCode.data,
    );
  }
  final value = annotation.computeConstantValue();
  if (value == null) {
    throw AxleException(
      'Could not evaluate an annotation on ${elementLabel(element)}.',
      exitCode: AxleExitCode.data,
    );
  }
  return value;
}

/// Turns a Dart member name into its serialized name.
typedef NameTransform = String Function(String name);

/// The options of a `@JsonSerializable` annotation that change the JSON.
class JsonSerializableData {
  /// Creates annotation data.
  const JsonSerializableData({this.fieldRename, this.ignoreUnannotated});

  /// The `FieldRename` constant name, including `none`, or `null` when the
  /// annotation does not set it. An unset value falls back to `build.yaml`.
  final String? fieldRename;

  /// Whether only `@JsonKey` fields are serialized, or `null` when unset.
  final bool? ignoreUnannotated;
}

/// Reads `@JsonSerializable` on [element], if present.
JsonSerializableData? readJsonSerializable(Element element) {
  final found = _jsonAnnotation(element, 'JsonSerializable');
  if (found == null) return null;
  return JsonSerializableData(
    fieldRename: found.$2.getField('fieldRename')?.variable?.name,
    ignoreUnannotated: boolField(found.$2, 'ignoreUnannotated'),
  );
}

/// Reads how a serialization package renames the members of [element].
///
/// Supports `json_serializable` (`@JsonSerializable` / `@JsonEnum`
/// `fieldRename`) and `dart_mappable` (`@MappableClass` / `@MappableEnum`
/// `caseStyle`). An option the annotation leaves unset falls back to the
/// project-wide value in [options], as the builders do:
///
/// * [jsonDefaults] applies `json_serializable`'s `field_rename` to a class
///   that json_serializable processes without the annotation, such as a freezed
///   class with a `fromJson` factory. Classes with `@JsonSerializable` get the
///   default automatically.
/// `dart_mappable_builder`'s `caseStyle` and `enumCaseStyle` apply to classes
/// and enums annotated with `@MappableClass` and `@MappableEnum`. The builder
/// does not map an unannotated enum, so it keeps its Dart names.
///
/// Returns `null` when [element] keeps Dart names.
NameTransform? readNameTransform(
  Element element, {
  required bool forEnum,
  BuildOptions options = BuildOptions.none,
  bool jsonDefaults = false,
}) {
  if (forEnum) {
    final rename = readFieldRename(element, forEnum: true);
    if (rename != null) return (name) => applyFieldRename(name, rename);
  } else {
    final json = readJsonSerializable(element);
    if (json != null || jsonDefaults) {
      final rename = json?.fieldRename ?? options.jsonFieldRename;
      if (rename != null && rename != 'none') {
        return (name) => applyFieldRename(name, rename);
      }
    }
  }

  final mappable = _annotationFrom(
    element,
    forEnum ? 'MappableEnum' : 'MappableClass',
    'dart_mappable',
  );
  final style = _fieldIncludingSuper(mappable?.$2, 'caseStyle');
  if (style != null && !style.isNull) return _caseStyle(style);
  if (mappable != null) {
    return forEnum ? options.mappableEnumCaseStyle : options.mappableCaseStyle;
  }
  return null;
}

/// Reads `@JsonKey` presence, which `ignoreUnannotated` depends on.
bool hasJsonKey(Element element) => readJsonKey(element) != null;

/// Reads [name] from [value], falling back to its superclass constants.
///
/// The analyzer exposes the superclass part of a constant under `(super)`.
DartObject? _fieldIncludingSuper(DartObject? value, String name) {
  for (
    var current = value;
    current != null;
    current = current.getField('(super)')
  ) {
    final field = current.getField(name);
    if (field != null) return field;
  }
  return null;
}

/// Re-implements `dart_mappable`'s `CaseStyle.transform` for a constant
/// `CaseStyle` value.
NameTransform _caseStyle(DartObject style) {
  String? transformName(DartObject? value) =>
      value == null || value.isNull ? null : value.variable?.name;
  return caseTransform(
    head: transformName(style.getField('head')),
    tail: transformName(style.getField('tail')),
    separator: style.getField('separator')?.toStringValue() ?? '',
  );
}

/// Builds a name transform from `dart_mappable` case-style parts.
///
/// [head] and [tail] are `TextTransform` names (`lowerCase`, `upperCase`,
/// `capitalCase`); [head] applies to the first word and [tail] to the rest.
NameTransform caseTransform({
  String? head,
  String? tail,
  String separator = '',
}) {
  final splitter = RegExp(r'[ ./_\-\\]+|(?<=[a-z])(?=[A-Z])');

  String apply(String? transform, String word) {
    return switch (transform) {
      'upperCase' => word.toUpperCase(),
      'lowerCase' => word.toLowerCase(),
      'capitalCase' when word.isNotEmpty =>
        '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      _ => word,
    };
  }

  return (name) {
    var words = name.split(splitter);
    if (head != null) {
      words = [
        apply(head, words.first),
        for (final word in words.skip(1)) apply(tail, word),
      ];
    } else if (tail != null) {
      words = [for (final word in words) apply(tail, word)];
    }
    return words.join(separator);
  };
}

/// Parses a `dart_mappable_builder` `caseStyle` option such as `snakeCase`.
///
/// Mirrors `CaseStyle.fromString`: the six named styles and
/// `custom(<transforms>,<separator>)`. Returns `null` for anything else, which
/// the builder ignores.
NameTransform? caseStyleFromString(String value) {
  switch (value) {
    case 'camelCase':
      return caseTransform(head: 'lowerCase', tail: 'capitalCase');
    case 'pascalCase':
      return caseTransform(tail: 'capitalCase');
    case 'snakeCase':
      return caseTransform(tail: 'lowerCase', separator: '_');
    case 'paramCase':
      return caseTransform(tail: 'lowerCase', separator: '-');
    case 'lowerCase':
      return caseTransform(tail: 'lowerCase');
    case 'upperCase':
      return caseTransform(tail: 'upperCase');
  }
  final custom = RegExp(r'^custom\(([luc][luc]?)?,(.?)\)$').firstMatch(value);
  if (custom == null) return null;
  String? letter(String character) => switch (character) {
    'l' => 'lowerCase',
    'u' => 'upperCase',
    'c' => 'capitalCase',
    _ => null,
  };
  final transforms = custom.group(1) ?? '';
  return caseTransform(
    head: transforms.length == 2 ? letter(transforms[0]) : null,
    tail: transforms.isEmpty
        ? null
        : letter(transforms[transforms.length == 2 ? 1 : 0]),
    separator: custom.group(2) ?? '',
  );
}

/// Reads `@MappableField(key: ...)` on [element], if present.
String? readMappableKey(Element element) {
  final found = _annotationFrom(element, 'MappableField', 'dart_mappable');
  return found == null ? null : stringField(found.$2, 'key');
}

/// Reads the serialized value of an enum constant.
///
/// Looks for `@JsonValue` and `@MappableValue`. Returns `null` when the
/// constant has neither.
Object? readEnumValue(Element constant) {
  final json = _annotationFrom(constant, 'JsonValue', 'json_annotation');
  if (json != null) return constValue(json.$2.getField('value'));
  final mappable = _annotationFrom(constant, 'MappableValue', 'dart_mappable');
  return mappable == null ? null : constValue(mappable.$2.getField('value'));
}

/// What axle needs from a `@Freezed` annotation.
class FreezedData {
  /// Creates freezed data.
  const FreezedData({this.unionKey});

  /// The JSON key that selects the union variant, when set.
  final String? unionKey;
}

/// Reads `@freezed`, `@unfreezed`, or `@Freezed(...)` on [element].
FreezedData? readFreezed(ClassElement element) {
  for (final annotation in element.metadata.annotations) {
    final target = annotation.element;
    if (target is GetterElement &&
        (target.name == 'freezed' || target.name == 'unfreezed') &&
        target.library.uri.toString().contains('freezed_annotation')) {
      return const FreezedData();
    }
  }
  final found = _annotationFrom(element, 'Freezed', 'freezed_annotation');
  return found == null
      ? null
      : FreezedData(unionKey: stringField(found.$2, 'unionKey'));
}

/// Reads `@Default(value)` on a freezed constructor parameter.
Object? readFreezedDefault(Element parameter) {
  final found = _annotationFrom(parameter, 'Default', 'freezed_annotation');
  return found == null ? null : constValue(found.$2.getField('defaultValue'));
}

/// Reads `@FreezedUnionValue(value)` on a freezed factory constructor.
String? readFreezedUnionValue(Element constructor) {
  final found = _annotationFrom(
    constructor,
    'FreezedUnionValue',
    'freezed_annotation',
  );
  return found == null ? null : stringField(found.$2, 'value');
}

/// What a custom converter tells axle about a property's JSON form.
class WireType {
  /// No converter applies.
  const WireType.none() : type = null, converter = false;

  /// A converter applies, and [type] is the JSON type it produces.
  const WireType.known(DartType this.type) : converter = true;

  /// A converter applies, but its JSON type could not be determined.
  const WireType.unknown() : type = null, converter = true;

  /// The JSON type produced by the converter, when known.
  final DartType? type;

  /// Whether a custom converter changes the JSON form of the property.
  final bool converter;
}

/// Finds a custom converter that changes how [source] is serialized.
///
/// Understands `@JsonKey(toJson:)` / `@JsonKey(fromJson:)`, field-level
/// `JsonConverter` annotations, and class-level `JsonConverter` annotations
/// on [owner] whose value type matches [fieldType]. The JSON type is taken
/// from the converter's second type argument or the function's return type.
/// `@MappableField(hook:)` is detected but its JSON type is unknown.
WireType readWireType(Element source, Element? owner, DartType fieldType) {
  final jsonKey = _jsonAnnotation(source, 'JsonKey');
  if (jsonKey != null) {
    final toJson = jsonKey.$2.getField('toJson')?.toFunctionValue();
    if (toJson != null) return _wireOf(toJson.returnType);
    final fromJson = jsonKey.$2.getField('fromJson')?.toFunctionValue();
    if (fromJson != null) {
      final parameters = fromJson.formalParameters;
      return parameters.isEmpty
          ? const WireType.unknown()
          : _wireOf(parameters.first.type);
    }
  }

  for (final target in [source, ?owner]) {
    for (final annotation in target.metadata.annotations) {
      final value = _constantOrNull(annotation);
      final converter = value?.type is InterfaceType
          ? _converterTypes(value!.type! as InterfaceType)
          : null;
      if (converter == null) continue;
      if (!identical(target, source) &&
          converter.value.element != fieldType.element) {
        continue;
      }
      return _wireOf(converter.json);
    }
  }

  final mappable = _annotationFrom(source, 'MappableField', 'dart_mappable');
  if (mappable != null) {
    final hook = mappable.$2.getField('hook');
    if (hook != null && !hook.isNull) return const WireType.unknown();
  }
  return const WireType.none();
}

WireType _wireOf(DartType type) {
  if (type is DynamicType || type.isDartCoreObject || type is VoidType) {
    return const WireType.unknown();
  }
  return WireType.known(type);
}

DartObject? _constantOrNull(ElementAnnotation annotation) {
  final errors = annotation.constantEvaluationErrors;
  if (errors != null && errors.isNotEmpty) return null;
  return annotation.computeConstantValue();
}

({DartType value, DartType json})? _converterTypes(InterfaceType type) {
  for (final supertype in [type, ...type.allSupertypes]) {
    if (supertype.element.name == 'JsonConverter' &&
        supertype.element.library.uri.toString().contains('json_annotation') &&
        supertype.typeArguments.length == 2) {
      return (
        value: supertype.typeArguments[0],
        json: supertype.typeArguments[1],
      );
    }
  }
  return null;
}
