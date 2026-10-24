/// Builds reusable component schemas from analyzer types.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:axle_core/axle_core.dart';

import '../errors.dart';
import 'annotations.dart';

/// A registry of component schemas built from analyzer types.
class SchemaRegistry {
  final Map<String, OpenApiSchema> _schemas = {};
  final Map<int, String> _namesByElement = {};
  final Map<String, int> _nameOwners = {};
  final Set<String> _inProgress = {};

  /// Non-fatal issues encountered while building schemas.
  final List<String> warnings = [];

  /// The component schemas, sorted by name.
  Map<String, OpenApiSchema> get schemas {
    final names = _schemas.keys.toList()..sort();
    return {for (final name in names) name: _schemas[name]!};
  }

  /// Registers [element] and returns its component name.
  String registerClass(
    ClassElement element, {
    String? nameOverride,
    String? description,
  }) {
    final name = _nameFor(element, override: nameOverride);
    if (_schemas.containsKey(name) || _inProgress.contains(name)) return name;

    _inProgress.add(name);
    try {
      if (element.typeParameters.isNotEmpty) {
        throw AxleException(
          'Generic classes are not supported: ${element.name}. '
          'Use a concrete DTO class instead.',
          exitCode: AxleExitCode.data,
        );
      }

      final schemaAnnotation = annotationNamed(element, 'ApiSchema');
      final schemaData = schemaAnnotation == null
          ? null
          : readApiSchema(schemaAnnotation);
      final resolvedDescription = description ?? schemaData?.description;

      if (schemaData != null && schemaData.oneOf.isNotEmpty) {
        final discriminator = schemaData.discriminator;
        if (discriminator != null &&
            discriminator.propertyName.trim().isEmpty) {
          throw AxleException(
            'Discriminator for ${element.name} must have a property name.',
            exitCode: AxleExitCode.data,
          );
        }
        _schemas[name] = OpenApiSchema.oneOf(
          [
            for (final type in schemaData.oneOf)
              schemaForType(type, context: '${element.name}.oneOf'),
          ],
          description: resolvedDescription,
          discriminator: discriminator == null
              ? null
              : OpenApiDiscriminator(
                  discriminator.propertyName,
                  mapping: discriminator.mapping,
                ),
        );
        return name;
      }
      if (schemaData?.discriminator != null) {
        throw AxleException(
          '${element.name} declares a discriminator without `oneOf`.',
          exitCode: AxleExitCode.data,
        );
      }

      final properties = <String, OpenApiSchema>{};
      final required = <String>[];
      final fields = _fieldsOf(element)
        ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      for (final field in fields) {
        final property = _propertyFor(
          field,
          context: '${element.name}.${field.name}',
        );
        if (property == null) continue;
        if (properties.containsKey(property.name)) {
          throw AxleException(
            'Duplicate JSON property `${property.name}` in '
            '${element.name}. Check @JsonKey and @ApiProperty names.',
            exitCode: AxleExitCode.data,
          );
        }
        properties[property.name] = property.schema;
        if (property.required) required.add(property.name);
      }

      final sortedProperties = {
        for (final key in properties.keys.toList()..sort())
          key: properties[key]!,
      };
      required.sort();

      _schemas[name] = OpenApiSchema.object(
        properties: sortedProperties,
        requiredProperties: required.isEmpty ? null : required,
        description: resolvedDescription,
      );
      return name;
    } finally {
      _inProgress.remove(name);
    }
  }

  /// Builds a schema for [type].
  OpenApiSchema schemaForType(DartType type, {required String context}) {
    var effective = type;
    while (effective.isDartAsyncFuture || effective.isDartAsyncFutureOr) {
      if (effective is! ParameterizedType || effective.typeArguments.isEmpty) {
        return OpenApiSchema.any();
      }
      effective = effective.typeArguments.first;
    }

    final schema = _baseSchema(effective, context: context);
    return _isNullable(effective) ? schema.asNullable() : schema;
  }

  OpenApiSchema _baseSchema(DartType type, {required String context}) {
    if (type is DynamicType) return OpenApiSchema.any();
    if (type is VoidType) return OpenApiSchema.nullSchema();
    if (type is NeverType) return OpenApiSchema.any();
    if (type is TypeParameterType) {
      throw _unsupported(type, context);
    }
    if (type is FunctionType) {
      throw _unsupported(type, context);
    }
    if (type is RecordType) {
      throw _unsupported(type, context);
    }
    if (type.isDartCoreFunction) {
      throw _unsupported(type, context);
    }

    if (type.isDartCoreInt) return const OpenApiSchema.integer();
    if (type.isDartCoreDouble || type.isDartCoreNum) {
      return const OpenApiSchema.number();
    }
    if (type.isDartCoreBool) return const OpenApiSchema.boolean();
    if (type.isDartCoreString) return const OpenApiSchema.string();
    if (type.isDartCoreObject) return OpenApiSchema.any();

    if (_isNamed(type, 'dart:core', 'Null')) {
      return const OpenApiSchema.nullSchema();
    }
    if (_isNamed(type, 'dart:core', 'DateTime')) {
      return const OpenApiSchema.dateTime();
    }
    if (_isNamed(type, 'dart:core', 'Uri')) {
      return const OpenApiSchema.uri();
    }
    if (_isNamed(type, 'dart:core', 'Duration')) {
      return const OpenApiSchema.duration();
    }
    if (_isNamed(type, 'dart:core', 'BigInt')) {
      return const OpenApiSchema.integer(format: 'int64');
    }
    if (_isNamed(type, 'dart:typed_data', 'Uint8List') ||
        _isNamed(type, 'dart:typed_data', 'ByteData')) {
      return const OpenApiSchema.string(format: 'byte');
    }

    if (type.isDartCoreList || type.isDartCoreSet || type.isDartCoreIterable) {
      return OpenApiSchema.array(_itemSchema(type, context: context));
    }

    if (type.isDartCoreMap) {
      return _mapSchema(type, context: context);
    }

    if (type is InterfaceType) {
      final element = type.element;
      if (element is EnumElement) {
        return OpenApiSchema.enumString(
          [
            for (final constant in element.constants) constant.name ?? '',
          ].where((name) => name.isNotEmpty).toList(),
        );
      }
      if (element is ClassElement) {
        final name = registerClass(element);
        return OpenApiSchema.ref(name);
      }
    }

    throw _unsupported(type, context);
  }

  OpenApiSchema _itemSchema(DartType type, {required String context}) {
    if (type is! ParameterizedType || type.typeArguments.isEmpty) {
      return OpenApiSchema.any();
    }
    return schemaForType(type.typeArguments.first, context: '$context[]');
  }

  OpenApiSchema _mapSchema(DartType type, {required String context}) {
    if (type is! ParameterizedType || type.typeArguments.length < 2) {
      return OpenApiSchema.object(additionalProperties: true);
    }
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (!(keyType.isDartCoreString ||
        keyType.isDartCoreObject ||
        keyType is DynamicType)) {
      warnings.add(
        'Map keys in $context are not Strings; JSON object keys must be '
        'strings. The generated schema still uses an object.',
      );
    }
    return OpenApiSchema.object(
      additionalProperties: schemaForType(valueType, context: '$context{}'),
    );
  }

  List<FieldElement> _fieldsOf(ClassElement element) {
    final fields = <String, FieldElement>{};
    void addFields(InterfaceElement type) {
      for (final field in type.fields) {
        if (field.isStatic ||
            field.isPrivate ||
            field.isEnumConstant ||
            field.isOriginEnumValues ||
            field.isOriginGetterSetter) {
          continue;
        }
        final name = field.name;
        if (name == null || name.isEmpty) continue;
        fields.putIfAbsent(name, () => field);
      }
    }

    addFields(element);
    for (final supertype in element.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      final libraryUri = supertype.element.library.uri.toString();
      if (libraryUri == 'dart:core') continue;
      addFields(supertype.element);
    }
    return fields.values.toList();
  }

  _Property? _propertyFor(FieldElement field, {required String context}) {
    final property = readApiProperty(field);
    if (property?.ignore ?? false) return null;

    final jsonKey = readJsonKey(field);
    if (jsonKey != null && !jsonKey.includeToJson && !jsonKey.includeFromJson) {
      return null;
    }

    final name = property?.name ?? jsonKey?.name ?? field.name;
    if (name == null || name.isEmpty) return null;

    var schema = schemaForType(field.type, context: context);
    final description =
        property?.description ?? cleanDocComment(field.documentationComment);
    if (description != null) schema = schema.withDescription(description);
    if (property?.example != null)
      schema = schema.withExample(property!.example);
    if (property != null) {
      schema = schema.withConstraints(
        format: property.format,
        enumValues: property.enumValues,
        minimum: property.minimum,
        maximum: property.maximum,
        minLength: property.minLength,
        maxLength: property.maxLength,
        pattern: property.pattern,
      );
    }
    if (jsonKey?.defaultValue != null) {
      schema = schema.withDefaultValue(jsonKey!.defaultValue);
    }

    final required =
        property?.required ??
        (!_isNullable(field.type) && jsonKey?.defaultValue == null);

    return _Property(name: name, schema: schema, required: required);
  }

  String _nameFor(ClassElement element, {String? override}) {
    final identifier = element.id;
    final existing = _namesByElement[identifier];
    if (existing != null) return existing;

    final schemaAnnotation = annotationNamed(element, 'ApiSchema');
    final preferred =
        override ??
        (schemaAnnotation == null
            ? null
            : readApiSchema(schemaAnnotation).name) ??
        element.name ??
        'Anonymous';

    var name = _sanitizeName(preferred);
    var suffix = 2;
    while (_nameOwners.containsKey(name) && _nameOwners[name] != identifier) {
      name = '${_sanitizeName(preferred)}_${suffix++}';
    }
    _nameOwners[name] = identifier;
    _namesByElement[identifier] = name;
    return name;
  }

  String _sanitizeName(String value) {
    var result = value.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (result.isEmpty) result = 'Schema';
    if (RegExp(r'^[0-9]').hasMatch(result)) result = '_$result';
    return result;
  }

  bool _isNullable(DartType type) {
    return type is DynamicType ||
        type.nullabilitySuffix != NullabilitySuffix.none;
  }

  bool _isNamed(DartType type, String library, String name) {
    return type.element?.name == name &&
        type.element?.library?.uri.toString() == library;
  }

  AxleException _unsupported(DartType type, String context) {
    return AxleException(
      'Unsupported Dart type `$type` in $context.',
      exitCode: AxleExitCode.data,
    );
  }
}

class _Property {
  const _Property({
    required this.name,
    required this.schema,
    required this.required,
  });

  final String name;
  final OpenApiSchema schema;
  final bool required;
}
