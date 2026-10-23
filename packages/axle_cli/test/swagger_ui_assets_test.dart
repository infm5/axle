import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  test('bundles the Swagger UI assets used by axle gen', () async {
    final assets = await loadSwaggerUiAssets();

    expect(swaggerUiVersion, '5.34.0');
    expect(assets.keys, unorderedEquals(swaggerUiAssetFiles));
    expect(assets['swagger-ui.css']!.length, greaterThan(1000));
    expect(assets['swagger-ui-bundle.js']!.length, greaterThan(1000000));
  });
}
