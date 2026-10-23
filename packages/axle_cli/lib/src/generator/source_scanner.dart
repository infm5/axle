/// Resolves Dart libraries from the configured source directories.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

import '../errors.dart';

/// Scans source directories with `package:analyzer`.
class SourceScanner {
  /// Creates a scanner.
  const SourceScanner({
    required this.projectRoot,
    required this.scanPaths,
    this.skipPaths = const {},
  });

  /// The project root.
  final Directory projectRoot;

  /// The directories or files to scan, relative to [projectRoot].
  final List<String> scanPaths;

  /// Absolute file paths to skip.
  final Set<String> skipPaths;

  /// Resolves and returns the libraries found under [scanPaths].
  Future<List<LibraryElement>> scan() async {
    final root = projectRoot.absolute;
    final includedPaths = <String>[];
    for (final relative in scanPaths) {
      final path = p.normalize(
        p.isAbsolute(relative) ? relative : p.join(root.path, relative),
      );
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.notFound) {
        throw AxleException(
          'Scan path not found: $relative',
          exitCode: AxleExitCode.config,
        );
      }
      includedPaths.add(path);
    }

    final AnalysisContextCollection collection;
    try {
      collection = AnalysisContextCollection(includedPaths: includedPaths);
    } on Object catch (error) {
      throw AxleException(
        'Could not start the Dart analyzer. Run `dart pub get` and try again. '
        '($error)',
        exitCode: AxleExitCode.config,
      );
    }

    try {
      final files = <String>{};
      for (final path in includedPaths) {
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.file) {
          if (path.endsWith('.dart') && !_skip(path)) files.add(path);
          continue;
        }
        await for (final entity in Directory(
          path,
        ).list(recursive: true, followLinks: false)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !_skip(entity.path)) {
            files.add(p.normalize(entity.path));
          }
        }
      }

      final sortedFiles = files.toList()..sort();
      final libraries = <String, LibraryElement>{};
      for (final file in sortedFiles) {
        final session = collection.contextFor(file).currentSession;
        final result = await session.getResolvedLibrary(file);
        if (result is ResolvedLibraryResult) {
          libraries[result.element.identifier] = result.element;
          continue;
        }
        final containing = await session.getResolvedLibraryContaining(file);
        if (containing is ResolvedLibraryResult) {
          libraries[containing.element.identifier] = containing.element;
        }
      }

      final result = libraries.values.toList()
        ..sort((a, b) => a.uri.toString().compareTo(b.uri.toString()));
      return result;
    } finally {
      await collection.dispose();
    }
  }

  bool _skip(String path) {
    final normalized = p.normalize(path);
    if (skipPaths.contains(normalized)) return true;
    final name = p.basename(normalized);
    return name.endsWith('.g.dart') || name.endsWith('.openapi.dart');
  }
}
