import 'dart:io';

import 'package:axle_cli/axle_cli.dart';
import 'package:test/test.dart';

void main() {
  test('SourceScanner rejects missing scan paths', () async {
    final scanner = SourceScanner(
      projectRoot: Directory.current,
      scanPaths: const ['does/not/exist'],
    );

    await expectLater(
      scanner.scan(),
      throwsA(
        isA<AxleException>().having(
          (error) => error.exitCode,
          'exitCode',
          AxleExitCode.config,
        ),
      ),
    );
  });
}
