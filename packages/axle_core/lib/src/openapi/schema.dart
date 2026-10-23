/// A JSON Schema 2020-12 object used in an OpenAPI 3.1 document.
library;

/// An immutable JSON Schema node.
///
/// This model intentionally covers the subset axle generates. Use [toJson] to
/// serialize it into an OpenAPI document.
class OpenApiSchema {
  /// Creates a schema with explicit values.
  const OpenApiSchema._({
    this.type,
    this.format,
    this.description,
    this.example,
    this.defaultValue,
    this.enumValues,
    this.items,
    this.properties,
    this.requiredProperties,
    this.additionalProperties,
    this.ref,
    this.nullable = false,
    this.minimum,
    this.maximum,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.oneOf,
  });

  /// Creates an unconstrained schema.
  const OpenApiSchema.any({
    this.description,
    this.example,
    this.nullable = false,
  }) : type = null,
       format = null,
       defaultValue = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a string schema.
  const OpenApiSchema.string({
    this.format,
    this.description,
    this.example,
    this.defaultValue,
    this.enumValues,
    this.nullable = false,
    this.minLength,
    this.maxLength,
    this.pattern,
  }) : type = 'string',
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       oneOf = null;

  /// Creates an integer schema.
  const OpenApiSchema.integer({
    this.format,
    this.description,
    this.example,
    this.defaultValue,
    this.nullable = false,
    this.minimum,
    this.maximum,
  }) : type = 'integer',
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a number schema.
  const OpenApiSchema.number({
    this.format,
    this.description,
    this.example,
    this.defaultValue,
    this.nullable = false,
    this.minimum,
    this.maximum,
  }) : type = 'number',
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a boolean schema.
  const OpenApiSchema.boolean({
    this.description,
    this.example,
    this.defaultValue,
    this.nullable = false,
  }) : type = 'boolean',
       format = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates an array schema.
  const OpenApiSchema.array(
    OpenApiSchema itemSchema, {
    this.description,
    this.example,
    this.defaultValue,
    this.nullable = false,
  }) : type = 'array',
       items = itemSchema,
       format = null,
       enumValues = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates an object schema.
  const OpenApiSchema.object({
    this.properties,
    this.requiredProperties,
    this.additionalProperties,
    this.description,
    this.example,
    this.defaultValue,
    this.nullable = false,
  }) : type = 'object',
       format = null,
       enumValues = null,
       items = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a schema referencing a component schema.
  const OpenApiSchema.ref(
    this.ref, {
    this.description,
    this.example,
    this.nullable = false,
  }) : type = null,
       format = null,
       defaultValue = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a schema matching one of [schemas].
  const OpenApiSchema.oneOf(
    List<OpenApiSchema> schemas, {
    this.description,
    this.example,
    this.nullable = false,
  }) : oneOf = schemas,
       type = null,
       format = null,
       defaultValue = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null;

  /// Creates a schema for an enum of string values.
  const OpenApiSchema.enumString(
    List<String> values, {
    this.description,
    this.example,
    this.defaultValue,
    this.nullable = false,
  }) : type = 'string',
       format = null,
       enumValues = values,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a schema that only matches `null`.
  const OpenApiSchema.nullSchema({this.description})
    : type = 'null',
      format = null,
      example = null,
      defaultValue = null,
      enumValues = null,
      items = null,
      properties = null,
      requiredProperties = null,
      additionalProperties = null,
      ref = null,
      nullable = false,
      minimum = null,
      maximum = null,
      minLength = null,
      maxLength = null,
      pattern = null,
      oneOf = null;

  /// Creates a string schema formatted as a date-time.
  const OpenApiSchema.dateTime({
    this.description,
    this.example,
    this.nullable = false,
  }) : type = 'string',
       format = 'date-time',
       defaultValue = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a string schema formatted as a URI.
  const OpenApiSchema.uri({
    this.description,
    this.example,
    this.nullable = false,
  }) : type = 'string',
       format = 'uri',
       defaultValue = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// Creates a string schema formatted as a duration.
  const OpenApiSchema.duration({
    this.description,
    this.example,
    this.nullable = false,
  }) : type = 'string',
       format = 'duration',
       defaultValue = null,
       enumValues = null,
       items = null,
       properties = null,
       requiredProperties = null,
       additionalProperties = null,
       ref = null,
       minimum = null,
       maximum = null,
       minLength = null,
       maxLength = null,
       pattern = null,
       oneOf = null;

  /// The JSON type, or `null` when the schema does not constrain the type.
  final String? type;

  /// The JSON Schema format.
  final String? format;

  /// A description of the schema.
  final String? description;

  /// An example value.
  final Object? example;

  /// The default value.
  final Object? defaultValue;

  /// The allowed string values when this schema describes an enum.
  final List<Object?>? enumValues;

  /// The item schema when [type] is `array`.
  final OpenApiSchema? items;

  /// The property schemas when [type] is `object`.
  final Map<String, OpenApiSchema>? properties;

  /// The names of required properties.
  final List<String>? requiredProperties;

  /// Whether additional properties are allowed, or the schema they must match.
  final Object? additionalProperties;

  /// The component schema name when this schema is a `$ref`.
  final String? ref;

  /// Whether `null` is accepted in addition to the described type.
  final bool nullable;

  /// The inclusive minimum for numeric schemas.
  final num? minimum;

  /// The inclusive maximum for numeric schemas.
  final num? maximum;

  /// The minimum length for string schemas.
  final int? minLength;

  /// The maximum length for string schemas.
  final int? maxLength;

  /// A regular expression the string must match.
  final String? pattern;

  /// A list of schemas where exactly one must match.
  final List<OpenApiSchema>? oneOf;

  /// Returns a copy of this schema that also accepts `null`.
  OpenApiSchema asNullable() => OpenApiSchema._(
    type: type,
    format: format,
    description: description,
    example: example,
    defaultValue: defaultValue,
    enumValues: enumValues,
    items: items,
    properties: properties,
    requiredProperties: requiredProperties,
    additionalProperties: additionalProperties,
    ref: ref,
    nullable: true,
    minimum: minimum,
    maximum: maximum,
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    oneOf: oneOf,
  );

  /// Returns a copy of this schema with [description].
  OpenApiSchema withDescription(String? description) => OpenApiSchema._(
    type: type,
    format: format,
    description: description,
    example: example,
    defaultValue: defaultValue,
    enumValues: enumValues,
    items: items,
    properties: properties,
    requiredProperties: requiredProperties,
    additionalProperties: additionalProperties,
    ref: ref,
    nullable: nullable,
    minimum: minimum,
    maximum: maximum,
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    oneOf: oneOf,
  );

  /// Returns a copy of this schema with [example].
  OpenApiSchema withExample(Object? example) => OpenApiSchema._(
    type: type,
    format: format,
    description: description,
    example: example,
    defaultValue: defaultValue,
    enumValues: enumValues,
    items: items,
    properties: properties,
    requiredProperties: requiredProperties,
    additionalProperties: additionalProperties,
    ref: ref,
    nullable: nullable,
    minimum: minimum,
    maximum: maximum,
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    oneOf: oneOf,
  );

  /// Returns a copy of this schema with [defaultValue].
  OpenApiSchema withDefaultValue(Object? defaultValue) => OpenApiSchema._(
    type: type,
    format: format,
    description: description,
    example: example,
    defaultValue: defaultValue,
    enumValues: enumValues,
    items: items,
    properties: properties,
    requiredProperties: requiredProperties,
    additionalProperties: additionalProperties,
    ref: ref,
    nullable: nullable,
    minimum: minimum,
    maximum: maximum,
    minLength: minLength,
    maxLength: maxLength,
    pattern: pattern,
    oneOf: oneOf,
  );

  /// Serializes this schema to JSON.
  Map<String, Object?> toJson() {
    if (ref != null) {
      final resolvedRef = _resolvedRef(ref!);
      final result = <String, Object?>{};
      if (nullable) {
        result['anyOf'] = [
          {r'$ref': resolvedRef},
          {'type': 'null'},
        ];
      } else {
        result[r'$ref'] = resolvedRef;
      }
      _writeMetadata(result);
      return result;
    }

    final result = <String, Object?>{};
    if (type != null) {
      result['type'] = nullable && type != 'null' ? [type, 'null'] : type;
    }

    if (enumValues != null) {
      final values = [...enumValues!];
      if (nullable && !values.contains(null)) values.add(null);
      result['enum'] = values;
    }

    if (items != null) result['items'] = items!.toJson();
    if (properties != null) {
      result['properties'] = {
        for (final entry in properties!.entries)
          entry.key: entry.value.toJson(),
      };
    }
    if (requiredProperties != null && requiredProperties!.isNotEmpty) {
      result['required'] = requiredProperties;
    }
    if (additionalProperties != null) {
      final value = additionalProperties;
      result['additionalProperties'] =
          value is OpenApiSchema ? value.toJson() : value;
    }
    if (oneOf != null) {
      final schemas = [...oneOf!];
      if (nullable) schemas.add(const OpenApiSchema.nullSchema());
      result['oneOf'] = [for (final schema in schemas) schema.toJson()];
    }
    if (format != null) result['format'] = format;
    if (minimum != null) result['minimum'] = minimum;
    if (maximum != null) result['maximum'] = maximum;
    if (minLength != null) result['minLength'] = minLength;
    if (maxLength != null) result['maxLength'] = maxLength;
    if (pattern != null) result['pattern'] = pattern;

    _writeMetadata(result);
    return result;
  }

  void _writeMetadata(Map<String, Object?> target) {
    if (description != null) target['description'] = description;
    if (example != null) target['example'] = example;
    if (defaultValue != null) target['default'] = defaultValue;
  }

  static String _resolvedRef(String ref) {
    if (ref.startsWith('#') || ref.contains('/')) return ref;
    return '#/components/schemas/$ref';
  }
}
