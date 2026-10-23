/// Bundled Swagger UI assets used by `axle gen`.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'errors.dart';

/// The bundled Swagger UI version.
const swaggerUiVersion = '5.34.0';

/// The files copied into the generated UI asset directory.
const swaggerUiAssetFiles = ['swagger-ui.css', 'swagger-ui-bundle.js'];

/// Loads the bundled Swagger UI assets.
///
/// The assets are shipped with `axle_cli` and copied into
/// `generate.output.ui` by `axle gen`. The returned map is keyed by file name.
Future<Map<String, List<int>>> loadSwaggerUiAssets() async {
  final libraryUri = await Isolate.resolvePackageUri(
    Uri.parse('package:axle_cli/axle_cli.dart'),
  );
  if (libraryUri == null) {
    throw const AxleException(
      'Could not locate the bundled Swagger UI assets. '
      'Reinstall axle_cli and run `dart run axle_cli:axle gen` again.',
    );
  }

  final packageRoot = p.dirname(p.dirname(libraryUri.toFilePath()));
  final assetDirectory = Directory(p.join(packageRoot, 'assets', 'swagger-ui'));
  if (!assetDirectory.existsSync()) {
    throw AxleException(
      'Bundled Swagger UI assets are missing from ${assetDirectory.path}. '
      'Reinstall axle_cli and run `dart run axle_cli:axle gen` again.',
    );
  }

  final assets = <String, List<int>>{};
  for (final name in swaggerUiAssetFiles) {
    final file = File(p.join(assetDirectory.path, name));
    if (!file.existsSync()) {
      throw AxleException(
        'Bundled Swagger UI asset `$name` is missing from '
        '${assetDirectory.path}.',
      );
    }
    assets[name] = await file.readAsBytes();
  }
  return assets;
}
