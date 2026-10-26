import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

/// Fixture directories whose generated specs are checked in under
/// `test/golden/`.
///
/// Run `AXLE_UPDATE_GOLDEN=1 dart test test/golden_test.dart` to rewrite the
/// files after an intended change, then review the diff.
const _fixtures = [
  'composition',
  'contract',
  'converters',
  'freezed',
  'generics',
  'json_serializable',
  'media_types',
  'mappable',
  'route_targets',
  'sealed',
];

void main() {
  final update = Platform.environment['AXLE_UPDATE_GOLDEN'] == '1';

  for (final name in _fixtures) {
    test('$name matches its golden spec', () async {
      final result = await OpenApiGenerator(
        config: AxleConfig(
          title: 'Golden $name',
          version: '1.0.0',
          scan: ['test/fixtures/$name'],
        ),
        projectRoot: Directory.current,
      ).generate();
      final actual = generateJsonArtifact(result.document);
      final golden = File('test/golden/$name.json');

      if (update) {
        golden.parent.createSync(recursive: true);
        golden.writeAsStringSync(actual);
        return;
      }
      expect(
        golden.existsSync(),
        isTrue,
        reason: 'Missing ${golden.path}. Run with AXLE_UPDATE_GOLDEN=1.',
      );
      expect(
        actual,
        golden.readAsStringSync(),
        reason: 'Run with AXLE_UPDATE_GOLDEN=1 to accept an intended change.',
      );
    });
  }
}
