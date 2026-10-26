/// Builds reusable component schemas from analyzer types.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:axle_core/axle_core.dart';

import '../errors.dart';
import 'annotations.dart';
import 'build_options.dart';
import 'locations.dart';

/// A registry of component schemas built from analyzer types.
class SchemaRegistry {
  /// Creates a registry.
  ///
  /// [options] are the project-wide serializer options from `build.yaml`.
  SchemaRegistry({this.options = BuildOptions.none});

  /// The project-wide serializer options from `build.yaml`.
  final BuildOptions options;

  final Map<String, OpenApiSchema> _schemas = {};
  final Map<String, String> _namesByElement = {};
  final Map<String, String> _nameOwners = {};
  final Set<String> _inProgress = {};
  static const _maxNesting = 24;

  /// Non-fatal issues encountered while building schemas.
  final List<String> warnings = [];

  /// The component schemas, sorted by name.
  Map<String, OpenApiSchema> get schemas {
    final names = _schemas.keys.toList()..sort();
    return {for (final name in names) name: _schemas[name]!};
  }

  /// Registers [element] and returns its component name.
  ///
  /// Generic classes are registered once per instantiation: [type] carries the
  /// type arguments, and `Page<UserDto>` becomes the `Page_UserDto` schema.
  /// Without [type], the class is registered with its own type parameters as
  /// unconstrained (`dynamic`) arguments.
  String registerClass(
    ClassElement element, {
    InterfaceType? type,
    String? nameOverride,
    String? description,
  }) {
    final instance = type ?? element.thisType;
    final name = _nameFor(element, instance, override: nameOverride);
    if (_schemas.containsKey(name) || _inProgress.contains(name)) return name;
    if (_inProgress.length >= _maxNesting) {
      throw AxleException(
        'Generic class ${element.name} expands without end. Break the cycle '
        'with a concrete DTO class.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }

    _inProgress.add(name);
    try {
      final schemaAnnotation = annotationNamed(element, 'ApiSchema');
      final schemaData = schemaAnnotation == null
          ? null
          : readApiSchema(schemaAnnotation);
      final resolvedDescription = description ?? schemaData?.description;

      final composed = _composedSchema(
        element,
        instance,
        schemaData,
        resolvedDescription,
      );
      if (composed != null) {
        _schemas[name] = composed;
        return name;
      }
      final variant = _freezedVariant(element);
      if (variant != null) {
        _schemas[name] = _freezedSchema(
          element,
          instance,
          variant.factory,
          description: resolvedDescription,
          unionKey: variant.unionKey,
          unionValue: variant.unionValue,
          renameOwner: variant.base,
        );
        return name;
      }
      final freezed = readFreezed(element);
      final factory = freezed == null || element.isSealed
          ? null
          : _freezedFactory(element);
      if (factory != null) {
        _schemas[name] = _freezedSchema(
          element,
          instance,
          factory,
          description: resolvedDescription,
        );
        return name;
      }
      if (element.isSealed) {
        _schemas[name] = _sealedSchema(
          element,
          schemaData,
          resolvedDescription,
        );
        return name;
      }
      if (schemaData?.discriminator != null) {
        throw AxleException(
          '${element.name} declares a discriminator without `oneOf` or '
          '`anyOf`.',
          exitCode: AxleExitCode.data,
          location: locationOf(element),
        );
      }

      _schemas[name] = _objectSchema(
        element,
        instance,
        _fieldsOf(element),
        description: resolvedDescription,
      );
      return name;
    } finally {
      _inProgress.remove(name);
    }
  }

  /// Builds the `oneOf`, `anyOf`, or `allOf` schema an `@ApiSchema` asks for.
  ///
  /// Returns `null` when the annotation does not compose other schemas.
  OpenApiSchema? _composedSchema(
    ClassElement element,
    InterfaceType instance,
    ApiSchemaData? data,
    String? description,
  ) {
    if (data == null) return null;
    final kinds = [
      if (data.oneOf.isNotEmpty) 'oneOf',
      if (data.anyOf.isNotEmpty) 'anyOf',
      if (data.allOf.isNotEmpty) 'allOf',
    ];
    if (kinds.isEmpty) return null;
    if (kinds.length > 1) {
      throw AxleException(
        '@ApiSchema on ${element.name} sets ${kinds.join(' and ')}. Use only '
        'one of oneOf, anyOf, and allOf.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }

    final discriminator = _discriminatorFor(element, data);
    List<OpenApiSchema> refs(List<DartType> types, String kind) => [
      for (final type in types)
        schemaForType(type, context: '${element.name}.$kind'),
    ];

    if (data.oneOf.isNotEmpty || data.anyOf.isNotEmpty) {
      final members = refs(
        data.oneOf.isNotEmpty ? data.oneOf : data.anyOf,
        data.oneOf.isNotEmpty ? 'oneOf' : 'anyOf',
      );
      if (discriminator != null) {
        _checkDiscriminator(element, discriminator, [
          for (final member in members)
            if (member.ref case final String ref) ref,
        ]);
      }
      return data.oneOf.isNotEmpty
          ? OpenApiSchema.oneOf(
              members,
              description: description,
              discriminator: discriminator,
            )
          : OpenApiSchema.anyOf(
              members,
              description: description,
              discriminator: discriminator,
            );
    }

    if (discriminator != null) {
      throw AxleException(
        '${element.name} declares a discriminator with `allOf`. Put the '
        'discriminator on the base schema with `oneOf` or `anyOf`.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }
    final parts = refs(data.allOf, 'allOf');
    final own = _objectSchema(
      element,
      instance,
      _fieldsOf(element, inherited: false),
    );
    return OpenApiSchema.allOf([
      ...parts,
      if (own.properties?.isNotEmpty ?? false) own,
    ], description: description);
  }

  /// How json_serializable renames the properties of a freezed class.
  ///
  /// The annotation on the factory wins, then the one on the class, then the
  /// `field_rename` in `build.yaml`, which applies because freezed classes with
  /// a `fromJson` factory are processed by json_serializable.
  NameTransform? _freezedRename(
    ClassElement owner,
    ConstructorElement factory,
    bool jsonDefaults,
  ) {
    final raw =
        readJsonSerializable(factory)?.fieldRename ??
        readJsonSerializable(owner)?.fieldRename ??
        (jsonDefaults ? options.jsonFieldRename : null);
    if (raw == null || raw == 'none') return null;
    return (name) => applyFieldRename(name, raw);
  }

  /// Whether json_serializable processes [element] through a `fromJson` factory,
  /// as it does for freezed classes that declare one.
  bool _hasFromJson(Element element) {
    final constructors = switch (element) {
      InterfaceElement() => element.constructors,
      ConstructorElement() => [element],
      _ => const <ConstructorElement>[],
    };
    return constructors.any((c) => c.isFactory && c.name == 'fromJson');
  }

  /// Finds the factory of a freezed union that [element] implements.
  ///
  /// freezed generates one class per union variant (`Circle implements Shape`)
  /// and keeps its defaults and renames on the factory parameters, so the
  /// factory is the source of truth for the variant's properties.
  ({
    ClassElement base,
    ConstructorElement factory,
    String unionKey,
    String unionValue,
  })?
  _freezedVariant(ClassElement element) {
    for (final supertype in element.allSupertypes) {
      final base = supertype.element;
      if (base is! ClassElement || !base.isSealed) continue;
      final freezed = readFreezed(base);
      if (freezed == null) continue;
      for (final constructor in base.constructors) {
        final target = constructor.redirectedConstructor?.enclosingElement;
        if (target == null || target.id != element.id) continue;
        return (
          base: base,
          factory: constructor,
          unionKey: freezed.unionKey ?? 'runtimeType',
          unionValue: _freezedUnionValue(constructor),
        );
      }
    }
    return null;
  }

  String _freezedUnionValue(ConstructorElement constructor) {
    final declared = readFreezedUnionValue(constructor);
    if (declared != null) return declared;
    final name = constructor.name;
    return name == null || name.isEmpty || name == 'new' ? 'default' : name;
  }

  /// The unnamed redirecting factory of a freezed data class, if it has one.
  ConstructorElement? _freezedFactory(ClassElement element) {
    for (final constructor in element.constructors) {
      final name = constructor.name;
      if (constructor.isFactory &&
          constructor.redirectedConstructor != null &&
          (name == null || name.isEmpty || name == 'new')) {
        return constructor;
      }
    }
    return null;
  }

  /// Builds an object schema from the parameters of a freezed factory.
  ///
  /// freezed declares fields on a generated mixin as getters, so the factory
  /// parameters are the reliable list of properties.
  OpenApiSchema _freezedSchema(
    ClassElement element,
    InterfaceType instance,
    ConstructorElement factory, {
    String? description,
    String? unionKey,
    String? unionValue,
    ClassElement? renameOwner,
  }) {
    final owner = renameOwner ?? element;
    final jsonDefaults = _hasFromJson(owner) || _hasFromJson(factory);
    if (jsonDefaults && options.jsonIgnoreUnannotated) {
      throw AxleException(
        'build.yaml sets `ignore_unannotated: true`, which axle cannot apply to '
        'the freezed class ${element.name}. Set it with '
        '`@JsonSerializable(ignoreUnannotated: false)` on the class, or remove '
        'the option.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }
    final rename = _freezedRename(owner, factory, jsonDefaults);
    final properties = <String, OpenApiSchema>{};
    final required = <String>[];
    if (unionKey != null && unionValue != null) {
      // freezed writes the variant name under the union key when it encodes.
      properties[unionKey] = OpenApiSchema.enumString([unionValue]);
      required.add(unionKey);
    }
    for (final parameter in factory.formalParameters) {
      final parameterName = parameter.name;
      final property = _propertyFor(
        source: parameter,
        owner: element,
        declaredName: parameterName,
        type: parameterName == null
            ? parameter.type
            : instance
                      .lookUpGetter(parameterName, element.library)
                      ?.returnType ??
                  parameter.type,
        rename: rename,
        context: '${element.name}.$parameterName',
        defaultValue: readFreezedDefault(parameter),
      );
      if (property == null) continue;
      if (properties.containsKey(property.name)) {
        throw AxleException(
          'Duplicate JSON property `${property.name}` in ${element.name}. '
          'Check @JsonKey and @ApiProperty names.',
          exitCode: AxleExitCode.data,
          location: locationOf(parameter),
        );
      }
      properties[property.name] = property.schema;
      if (property.required) required.add(property.name);
    }
    required.sort();
    return OpenApiSchema.object(
      properties: {
        for (final key in properties.keys.toList()..sort())
          key: properties[key]!,
      },
      requiredProperties: required.isEmpty ? null : required,
      description: description,
    );
  }

  /// Builds the `oneOf` over the subtypes of the sealed [element].
  OpenApiSchema _sealedSchema(
    ClassElement element,
    ApiSchemaData? data,
    String? description,
  ) {
    if (element.typeParameters.isNotEmpty) {
      throw AxleException(
        'Generic sealed class ${element.name} cannot be expanded '
        'automatically. List the concrete subtypes with '
        '`@ApiSchema(oneOf: [...])`.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }
    final subtypes = _sealedSubtypes(element);
    if (subtypes.isEmpty) {
      throw AxleException(
        'Sealed class ${element.name} has no subtypes to describe.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }
    final names = [for (final subtype in subtypes) registerClass(subtype)];
    final discriminator =
        (data == null ? null : _discriminatorFor(element, data)) ??
        _freezedDiscriminator(element, subtypes, names);
    if (discriminator == null) {
      warnings.add(
        'Sealed class ${element.name} becomes a oneOf without a '
        'discriminator, so clients cannot tell its subtypes apart when their '
        'JSON overlaps. Add `@ApiSchema(discriminator: ApiDiscriminator(...))`.',
      );
    } else {
      _checkDiscriminator(element, discriminator, names);
    }
    return OpenApiSchema.oneOf(
      [for (final name in names) OpenApiSchema.ref(name)],
      description: description,
      discriminator: discriminator,
    );
  }

  /// Warns when a member of a discriminated union does not declare the
  /// discriminator property, because OpenAPI tools read it from the member.
  void _checkDiscriminator(
    ClassElement element,
    OpenApiDiscriminator discriminator,
    List<String> memberNames,
  ) {
    for (final member in memberNames) {
      final schema = _schemas[member];
      if (schema == null) continue;
      final properties = schema.properties;
      if (properties == null) continue;
      if (!properties.containsKey(discriminator.propertyName)) {
        warnings.add(
          'Discriminator property `${discriminator.propertyName}` of '
          '${element.name} is not declared by $member. Add a field or '
          '`@ApiProperty(name: \'${discriminator.propertyName}\')` so the '
          'schema documents it.',
        );
      }
    }
  }

  /// The union key and variant values of a freezed union.
  ///
  /// freezed writes the variant name under `unionKey` (default `runtimeType`)
  /// when it serializes a union.
  OpenApiDiscriminator? _freezedDiscriminator(
    ClassElement element,
    List<ClassElement> subtypes,
    List<String> names,
  ) {
    final freezed = readFreezed(element);
    if (freezed == null) return null;
    final mapping = <String, String>{};
    for (var i = 0; i < subtypes.length; i++) {
      for (final constructor in element.constructors) {
        final target = constructor.redirectedConstructor?.enclosingElement;
        if (target == null || target.id != subtypes[i].id) continue;
        mapping[_freezedUnionValue(constructor)] = names[i];
      }
    }
    return OpenApiDiscriminator(
      freezed.unionKey ?? 'runtimeType',
      mapping: mapping,
    );
  }

  OpenApiDiscriminator? _discriminatorFor(
    ClassElement element,
    ApiSchemaData data,
  ) {
    final discriminator = data.discriminator;
    if (discriminator == null) return null;
    if (discriminator.propertyName.trim().isEmpty) {
      throw AxleException(
        'Discriminator for ${element.name} must have a property name.',
        exitCode: AxleExitCode.data,
        location: locationOf(element),
      );
    }
    return OpenApiDiscriminator(
      discriminator.propertyName,
      mapping: discriminator.mapping,
    );
  }

  /// Builds an object schema from [fields], as seen from [instance].
  OpenApiSchema _objectSchema(
    ClassElement element,
    InterfaceType instance,
    List<FieldElement> fields, {
    String? description,
  }) {
    final rename = readNameTransform(element, forEnum: false, options: options);
    // json_serializable skips fields without @JsonKey when asked to, in the
    // annotation or project-wide.
    final json = readJsonSerializable(element);
    final ignoreUnannotated =
        json != null &&
        (json.ignoreUnannotated ?? options.jsonIgnoreUnannotated);
    final properties = <String, OpenApiSchema>{};
    final required = <String>[];
    final sorted = [...fields]
      ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    for (final field in sorted) {
      if (ignoreUnannotated && !hasJsonKey(field)) continue;
      final property = _propertyFor(
        source: field,
        owner: element,
        declaredName: field.name,
        type: _fieldType(instance, field),
        rename: rename,
        context: '${element.name}.${field.name}',
      );
      if (property == null) continue;
      if (properties.containsKey(property.name)) {
        throw AxleException(
          'Duplicate JSON property `${property.name}` in '
          '${element.name}. Check @JsonKey and @ApiProperty names.',
          exitCode: AxleExitCode.data,
          location: locationOf(field),
        );
      }
      properties[property.name] = property.schema;
      if (property.required) required.add(property.name);
    }

    required.sort();
    return OpenApiSchema.object(
      properties: {
        for (final key in properties.keys.toList()..sort())
          key: properties[key]!,
      },
      requiredProperties: required.isEmpty ? null : required,
      description: description,
    );
  }

  /// Whether [type] is raw byte data (`Uint8List` or `ByteData`).
  bool isByteData(DartType type) =>
      _isNamed(type, 'dart:typed_data', 'Uint8List') ||
      _isNamed(type, 'dart:typed_data', 'ByteData');

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
        return OpenApiSchema.enumString(_enumValues(element, context));
      }
      if (element is ClassElement) {
        final name = registerClass(element, type: type);
        return OpenApiSchema.ref(name);
      }
    }

    throw _unsupported(type, context);
  }

  /// The serialized values of [element].
  ///
  /// Honors `@JsonEnum`/`@JsonValue` and `@MappableEnum`/`@MappableValue`.
  List<String> _enumValues(EnumElement element, String context) {
    final rename = readNameTransform(element, forEnum: true, options: options);
    final values = <String>[];
    for (final constant in element.constants) {
      final name = constant.name;
      if (name == null || name.isEmpty) continue;
      final declared = readEnumValue(constant);
      if (declared is String) {
        values.add(declared);
        continue;
      }
      if (declared != null) {
        warnings.add(
          'Enum value ${element.name}.$name in $context uses a non-string '
          '@JsonValue or @MappableValue; its name was used instead.',
        );
      }
      values.add(rename == null ? name : rename(name));
    }
    return values;
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

  List<FieldElement> _fieldsOf(ClassElement element, {bool inherited = true}) {
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
    if (!inherited) return fields.values.toList();
    for (final supertype in element.allSupertypes) {
      if (supertype.isDartCoreObject) continue;
      final libraryUri = supertype.element.library.uri.toString();
      if (libraryUri == 'dart:core') continue;
      addFields(supertype.element);
    }
    return fields.values.toList();
  }

  _Property? _propertyFor({
    required Element source,
    Element? owner,
    required String? declaredName,
    required DartType type,
    required NameTransform? rename,
    required String context,
    Object? defaultValue,
  }) {
    final property = readApiProperty(source);
    if (property?.ignore ?? false) return null;

    final jsonKey = readJsonKey(source);
    if (jsonKey != null && !jsonKey.includeToJson && !jsonKey.includeFromJson) {
      return null;
    }

    final name =
        property?.name ??
        jsonKey?.name ??
        readMappableKey(source) ??
        (declaredName == null
            ? null
            : (rename == null ? declaredName : rename(declaredName)));
    if (name == null || name.isEmpty) return null;

    final wire = _wireType(source, owner, type, property, context);
    var schema = _schemaFor(source, wire, context: context);
    // The wire type comes from a literal or a converter, so the field decides
    // nullability.
    if (!identical(wire, type) && _isNullable(type)) {
      schema = schema.asNullable();
    }
    final description =
        property?.description ?? cleanDocComment(source.documentationComment);
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
    final fallback = jsonKey?.defaultValue ?? defaultValue;
    if (fallback != null) schema = schema.withDefaultValue(fallback);

    final required =
        property?.required ?? (!_isNullable(type) && fallback == null);

    return _Property(name: name, schema: schema, required: required);
  }

  /// The type whose schema describes [source] in JSON.
  ///
  /// An explicit `@ApiProperty(type:)` wins, then the JSON type of a custom
  /// converter, then the field's own type. A converter whose JSON type is
  /// unknown produces a warning, because the Dart type is probably wrong.
  DartType _wireType(
    Element source,
    Element? owner,
    DartType type,
    ApiPropertyData? property,
    String context,
  ) {
    final explicit = property?.type;
    if (explicit != null) return explicit;
    final converter = readWireType(source, owner, type);
    if (!converter.converter) return type;
    final wire = converter.type;
    if (wire != null) return wire;
    warnings.add(
      'Property $context uses a custom converter, so its JSON form may differ '
      'from the Dart type `$type`. The schema was built from the Dart type; '
      'set `@ApiProperty(type: ...)` to describe the JSON type.',
    );
    return type;
  }

  OpenApiSchema _schemaFor(
    Element source,
    DartType type, {
    required String context,
  }) {
    try {
      return schemaForType(type, context: context);
    } on AxleException catch (error) {
      throw error.withLocation(locationOf(source));
    }
  }

  /// The direct subtypes of the sealed [element], sorted by name.
  ///
  /// Dart requires them to live in the same library, so that library is
  /// enough to find all of them. Subtypes hidden with `@ApiSchema(ignore:)`
  /// are left out.
  List<ClassElement> _sealedSubtypes(ClassElement element) {
    bool extendsElement(ClassElement candidate) {
      return candidate.supertype?.element == element ||
          candidate.interfaces.any((type) => type.element == element) ||
          candidate.mixins.any((type) => type.element == element);
    }

    final subtypes = [
      for (final candidate in element.library.classes)
        if (candidate != element &&
            extendsElement(candidate) &&
            !_isIgnored(candidate))
          candidate,
    ]..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return subtypes;
  }

  bool _isIgnored(ClassElement element) {
    final annotation = annotationNamed(element, 'ApiSchema');
    return annotation != null && readApiSchema(annotation).ignore;
  }

  /// The type of [field] as seen from [instance], with type arguments applied.
  DartType _fieldType(InterfaceType instance, FieldElement field) {
    final name = field.name;
    if (name == null) return field.type;
    return instance.lookUpGetter(name, instance.element.library)?.returnType ??
        field.type;
  }

  String _nameFor(
    ClassElement element,
    InterfaceType instance, {
    String? override,
  }) {
    final identifier = _instanceKey(instance);
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

    final base = [
      _sanitizeName(preferred),
      for (final argument in instance.typeArguments) _typeLabel(argument),
    ].join('_');
    var name = base;
    var suffix = 2;
    while (_nameOwners.containsKey(name) && _nameOwners[name] != identifier) {
      name = '${base}_${suffix++}';
    }
    _nameOwners[name] = identifier;
    _namesByElement[identifier] = name;
    return name;
  }

  /// A key that tells apart instantiations of the same generic class.
  String _instanceKey(InterfaceType type) {
    if (type.typeArguments.isEmpty) return '${type.element.id}';
    return '${type.element.id}<'
        '${type.typeArguments.map(_typeKey).join(',')}>';
  }

  String _typeKey(DartType type) {
    final nullable = _isNullable(type) ? '?' : '';
    if (type is InterfaceType) return '${_instanceKey(type)}$nullable';
    return '${type.getDisplayString()}$nullable';
  }

  /// A name fragment for [type] used in generic schema names.
  String _typeLabel(DartType type) {
    final suffix = _isNullable(type) && type is! DynamicType ? '_Nullable' : '';
    if (type is InterfaceType) {
      final element = type.element;
      final annotation = element is ClassElement
          ? annotationNamed(element, 'ApiSchema')
          : null;
      final base = _sanitizeName(
        (annotation == null ? null : readApiSchema(annotation).name) ??
            element.name ??
            'Anonymous',
      );
      final label = [
        base,
        for (final argument in type.typeArguments) _typeLabel(argument),
      ].join('_');
      return '$label$suffix';
    }
    if (type is DynamicType) return 'Any';
    return '${_sanitizeName(type.getDisplayString().replaceAll('?', ''))}'
        '$suffix';
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
