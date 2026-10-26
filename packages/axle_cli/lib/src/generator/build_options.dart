/// Reads the serializer options a project sets in `build.yaml`.
///
/// `json_serializable` and `dart_mappable_builder` accept project-wide options
/// there, and some of them change the JSON a server sends. If axle ignored them
/// the spec would disagree with the server without any warning, so axle reads
/// the ones that change names or fields and fails on values it cannot honor.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../errors.dart';
import 'annotations.dart';

/// The `build.yaml` options that change the JSON of a model.
class BuildOptions {
  /// Creates options.
  const BuildOptions({
    this.jsonFieldRename,
    this.jsonIgnoreUnannotated = false,
    this.mappableCaseStyle,
    this.mappableEnumCaseStyle,
  });

  /// No options set.
  static const none = BuildOptions();

  /// `json_serializable`'s `field_rename`, such as `snake`, when set.
  final String? jsonFieldRename;

  /// `json_serializable`'s `ignore_unannotated`.
  final bool jsonIgnoreUnannotated;

  /// `dart_mappable_builder`'s `caseStyle` for classes, when set.
  final NameTransform? mappableCaseStyle;

  /// `dart_mappable_builder`'s `enumCaseStyle` for enums, when set.
  final NameTransform? mappableEnumCaseStyle;

  static const _fieldRenames = {
    'none',
    'kebab',
    'snake',
    'pascal',
    'screamingSnake',
  };

  /// Loads `build.yaml` from [projectRoot], or [none] when there is no file.
  ///
  /// Throws an [AxleException] with exit code 65 when an option holds a value
  /// the builder would reject or that axle cannot represent, and with code 78
  /// when the file is not valid YAML.
  static BuildOptions load(Directory projectRoot) {
    final file = File(p.join(projectRoot.path, 'build.yaml'));
    if (!file.existsSync()) return none;

    final Object? document;
    try {
      document = loadYaml(file.readAsStringSync());
    } on YamlException catch (error) {
      throw AxleException(
        'build.yaml is not valid YAML: ${error.message}',
        exitCode: AxleExitCode.config,
      );
    }
    if (document is! YamlMap) return none;

    final json = _optionSets(document, 'json_serializable');
    final mappable = _optionSets(document, 'dart_mappable_builder');

    final fieldRename = _single<String>(json, 'field_rename');
    if (fieldRename != null && !_fieldRenames.contains(fieldRename)) {
      throw AxleException(
        'build.yaml sets `field_rename: $fieldRename`, which json_serializable '
        'does not accept. Use one of ${_fieldRenames.join(', ')}.',
        exitCode: AxleExitCode.data,
      );
    }
    final ignoreUnannotated = _single<bool>(json, 'ignore_unannotated');

    return BuildOptions(
      jsonFieldRename: fieldRename == 'none' ? null : fieldRename,
      jsonIgnoreUnannotated: ignoreUnannotated ?? false,
      mappableCaseStyle: _caseStyleOption(mappable, 'caseStyle'),
      mappableEnumCaseStyle: _caseStyleOption(mappable, 'enumCaseStyle'),
    );
  }

  /// Every `options` map set for [package] in any target or in
  /// `global_options`, each tagged with where it came from.
  static List<(String, YamlMap)> _optionSets(YamlMap document, String package) {
    bool matches(Object? key) =>
        key is String && (key == package || key.startsWith('$package:'));

    final sets = <(String, YamlMap)>[];
    final targets = document['targets'];
    if (targets is YamlMap) {
      for (final target in targets.entries) {
        final builders = target.value is YamlMap
            ? (target.value as YamlMap)['builders']
            : null;
        if (builders is! YamlMap) continue;
        for (final builder in builders.entries) {
          if (!matches(builder.key)) continue;
          final value = builder.value;
          final options = value is YamlMap ? value['options'] : null;
          if (options is YamlMap) {
            sets.add((
              'targets.${target.key}.builders.${builder.key}',
              options,
            ));
          }
        }
      }
    }
    final global = document['global_options'];
    if (global is YamlMap) {
      for (final builder in global.entries) {
        if (!matches(builder.key)) continue;
        final value = builder.value;
        final options = value is YamlMap ? value['options'] : null;
        if (options is YamlMap) {
          sets.add(('global_options.${builder.key}', options));
        }
      }
    }
    return sets;
  }

  /// The value of [option] across [sets], or `null` when unset.
  ///
  /// Fails when two places set different values, because then it is unclear
  /// which one the builder uses.
  static T? _single<T>(List<(String, YamlMap)> sets, String option) {
    final seen = <String, Object?>{};
    for (final (where, options) in sets) {
      if (options.containsKey(option)) seen[where] = options[option];
    }
    if (seen.isEmpty) return null;
    if (seen.values.toSet().length > 1) {
      throw AxleException(
        'build.yaml sets `$option` to different values (${seen.entries.map((e) => '${e.key}: ${e.value}').join('; ')}). '
        'Keep one so axle and the builder agree.',
        exitCode: AxleExitCode.data,
      );
    }
    final value = seen.values.first;
    if (value is! T) {
      throw AxleException(
        'build.yaml sets `$option: $value`, but it must be a ${T == bool ? 'boolean' : 'string'}.',
        exitCode: AxleExitCode.data,
      );
    }
    return value;
  }

  static NameTransform? _caseStyleOption(
    List<(String, YamlMap)> sets,
    String option,
  ) {
    final value = _single<String>(sets, option);
    if (value == null) return null;
    if (value == 'none' || value == 'unmodified') return null;
    final style = caseStyleFromString(value);
    if (style == null) {
      throw AxleException(
        'build.yaml sets `$option: $value`, which dart_mappable_builder '
        'ignores. Use camelCase, pascalCase, snakeCase, paramCase, lowerCase, '
        'upperCase, or custom(...).',
        exitCode: AxleExitCode.data,
      );
    }
    return style;
  }
}
