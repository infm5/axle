import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  test('scans projects that exclude generated files from analysis', () async {
    final result = await OpenApiGenerator(
      config: AxleConfig(
        title: 'Excluded',
        version: '1.0.0',
        scan: const ['test/fixtures/excluded_files'],
      ),
      projectRoot: Directory.current,
    ).generate();

    expect(result.document.toJson()['paths'], contains('/things'));
  });
}
