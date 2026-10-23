/// The `axle gen` command.
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../artifacts.dart';
import '../config.dart';
import '../errors.dart';
import '../generator/openapi_generator.dart';
import '../swagger_ui_assets.dart';

/// Generates the OpenAPI JSON, YAML, and Dart artifacts.
class GenCommand extends Command<int> {
  /// Creates the command.
  GenCommand() {
    argParser
      ..addOption(
        'project',
        abbr: 'p',
        defaultsTo: '.',
        help: 'The Dart package root.',
      )
      ..addOption(
        'config',
        defaultsTo: AxleConfig.fileName,
        help: 'The configuration file, relative to the project root.',
      )
      ..addFlag(
        'check',
        negatable: false,
        help: 'Fail if the generated files are out of date instead of writing.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Print scan details and warnings.',
      );
  }

  @override
  String get name => 'gen';

  @override
  String get description =>
      'Generate the OpenAPI JSON, YAML, and Dart artifacts.';

  @override
  Future<int> run() async {
    final root = Directory(argResults!.option('project')!).absolute;
    final config = AxleConfig.load(
      root,
      configFileName: argResults!.option('config')!,
    );

    final result = await OpenApiGenerator(
      config: config,
      projectRoot: root,
    ).generate();

    for (final warning in result.warnings) {
      stderr.writeln('axle: warning: $warning');
    }

    final json = generateJsonArtifact(result.document);
    final yaml = generateYamlArtifact(result.document);
    final dart = generateDartArtifact(json);
    final jsonFile = _outputFile(root, config.jsonOutput);
    final yamlFile = _yamlFile(root, config.jsonOutput);
    final dartFile = _outputFile(root, config.dartOutput);
    final uiDirectory = _outputDirectory(root, config.swaggerUiOutput);
    final outputFiles = {
      p.normalize(jsonFile.absolute.path),
      p.normalize(yamlFile.absolute.path),
      p.normalize(dartFile.absolute.path),
      p.normalize(uiDirectory.absolute.path),
    };

    if (outputFiles.length != 4) {
      throw AxleException(
        'Generated JSON, YAML, UI, and Dart outputs must point to different '
        'paths.',
        exitCode: AxleExitCode.config,
      );
    }

    final swaggerUiAssets = await loadSwaggerUiAssets();

    if (argResults!.flag('check')) {
      final jsonMatches = _matches(jsonFile, json);
      final yamlMatches = _matches(yamlFile, yaml);
      final dartMatches = _matches(dartFile, dart);
      final uiMatches = _directoryMatches(uiDirectory, swaggerUiAssets);
      if (!jsonMatches || !yamlMatches || !dartMatches || !uiMatches) {
        final stale = [
          if (!jsonMatches) p.relative(jsonFile.path, from: root.path),
          if (!yamlMatches) p.relative(yamlFile.path, from: root.path),
          if (!dartMatches) p.relative(dartFile.path, from: root.path),
          if (!uiMatches) p.relative(uiDirectory.path, from: root.path),
        ].join(', ');
        throw AxleException(
          'Generated files are out of date: $stale. '
          'Run `dart run axle_cli:axle gen`.',
          exitCode: AxleExitCode.data,
        );
      }
      stdout.writeln('Generated files are up to date.');
      return AxleExitCode.success;
    }

    _write(jsonFile, json);
    _write(yamlFile, yaml);
    _write(dartFile, dart);
    _writeAssets(uiDirectory, swaggerUiAssets);

    stdout.writeln(
      'Generated ${result.document.paths.length} paths and '
      '${result.document.components.schemas.length} schemas.',
    );
    stdout
      ..writeln('  ${p.relative(jsonFile.path, from: root.path)}')
      ..writeln('  ${p.relative(yamlFile.path, from: root.path)}')
      ..writeln(
        '  ${p.relative(uiDirectory.path, from: root.path)} '
        '(${swaggerUiAssets.length} assets)',
      )
      ..writeln('  ${p.relative(dartFile.path, from: root.path)}');

    if (argResults!.flag('verbose')) {
      stdout.writeln('Scanned: ${config.scan.join(', ')}');
    }

    return AxleExitCode.success;
  }

  void _write(File file, String content) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  File _outputFile(Directory root, String path) {
    return File(p.isAbsolute(path) ? path : p.join(root.path, path));
  }

  File _yamlFile(Directory root, String jsonPath) {
    return File(p.setExtension(_outputFile(root, jsonPath).path, '.yaml'));
  }

  Directory _outputDirectory(Directory root, String path) {
    return Directory(p.isAbsolute(path) ? path : p.join(root.path, path));
  }

  bool _matches(File file, String expected) {
    return file.existsSync() && file.readAsStringSync() == expected;
  }

  bool _directoryMatches(Directory directory, Map<String, List<int>> assets) {
    if (!directory.existsSync()) return false;
    for (final entry in assets.entries) {
      final file = File(p.join(directory.path, entry.key));
      if (!file.existsSync()) return false;
      final actual = file.readAsBytesSync();
      if (actual.length != entry.value.length) return false;
      for (var i = 0; i < actual.length; i++) {
        if (actual[i] != entry.value[i]) return false;
      }
    }
    return true;
  }

  void _writeAssets(Directory directory, Map<String, List<int>> assets) {
    final type = FileSystemEntity.typeSync(directory.path);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      throw AxleException(
        '`generate.output.ui` must point to a directory, but '
        '`${directory.path}` is not a directory.',
        exitCode: AxleExitCode.config,
      );
    }
    directory.createSync(recursive: true);
    for (final entry in assets.entries) {
      File(
        p.join(directory.path, entry.key),
      ).writeAsBytesSync(entry.value, flush: true);
    }
  }
}
