/// Orchestrates source scanning and document generation.
library;

import 'dart:io';

import 'package:axle_core/axle_core.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import 'operation_builder.dart';
import 'schema_registry.dart';
import 'source_scanner.dart';

/// The result of one generation run.
class GeneratedSpec {
  /// Creates a generation result.
  const GeneratedSpec({required this.document, required this.warnings});

  /// The generated document.
  final OpenApiDocument document;

  /// Non-fatal issues encountered during generation.
  final List<String> warnings;
}

/// Generates an OpenAPI document for a project.
class OpenApiGenerator {
  /// Creates a generator.
  const OpenApiGenerator({required this.config, required this.projectRoot});

  /// The project configuration.
  final AxleConfig config;

  /// The project root.
  final Directory projectRoot;

  /// Scans the project and builds the document.
  Future<GeneratedSpec> generate() async {
    final root = projectRoot.absolute;
    final outputPath = p.normalize(
      p.isAbsolute(config.dartOutput)
          ? config.dartOutput
          : p.join(root.path, config.dartOutput),
    );
    final libraries = await SourceScanner(
      projectRoot: root,
      scanPaths: config.scan,
      skipPaths: {outputPath},
    ).scan();

    final registry = SchemaRegistry();
    if (libraries.isEmpty) {
      registry.warnings.add(
        'No Dart libraries found in ${config.scan.join(', ')}.',
      );
    }

    final document = OpenApiSpecBuilder(
      config: config,
      registry: registry,
    ).build(libraries);

    return GeneratedSpec(
      document: document,
      warnings: List.unmodifiable(registry.warnings),
    );
  }
}
